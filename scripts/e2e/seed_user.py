#!/usr/bin/env python3
"""Cria o usuário dos testes integrados do app (integration_test/) no ambiente local.

Cadastro e onboarding passam pela API real do gateway (código do email lido no Mailpit); só o
treino é inserido por SQL, para os testes não dependerem da geração pelo agent-v2 (lenta, gasta
LLM e muda a cada execução). Imprime em JSON as credenciais que o run.sh repassa ao app.

Uso: seed_user.py [--cleanup]   (--cleanup apaga todos os usuários e emails de e2e)
"""
import json
import random
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMPOSE = ["docker", "compose", "-f", str(ROOT / "docker-compose.dev.yml")]
GATEWAY = "http://localhost:3000"
MAILPIT = "http://localhost:8025"
EMAIL_DOMAIN = "e2e.personalia.test"
PASSWORD = "senha-e2e-123"


def request(method, url, body=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        sys.exit(f"{method} {url} -> {error.code}: {error.read().decode()}")


def psql(sql):
    result = subprocess.run(
        COMPOSE + ["exec", "-T", "postgres", "sh", "-c",
                   'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -v ON_ERROR_STOP=1'],
        input=sql, capture_output=True, text=True,
    )
    if result.returncode != 0:
        sys.exit(f"psql falhou: {result.stderr}")
    return result.stdout.strip()


def email_code(address, timeout=20):
    """Último código de 6 dígitos que chegou para o endereço no Mailpit."""
    query = urllib.parse.quote(f"to:{address}")
    deadline = time.time() + timeout
    while time.time() < deadline:
        messages = request("GET", f"{MAILPIT}/api/v1/search?query={query}")["messages"]
        for message in messages:
            for word in message["Snippet"].split():
                digits = word.strip(".:,")
                if len(digits) == 6 and digits.isdigit():
                    return digits
        time.sleep(1)
    sys.exit(f"nenhum código chegou para {address} no Mailpit")


def valid_cpf():
    base = [random.randint(0, 9) for _ in range(9)]
    for size in (9, 10):
        total = sum(d * w for d, w in zip(base, range(size + 1, 1, -1)))
        base.append((total * 10 % 11) % 10)
    return "".join(map(str, base))


def seed_workout(user_id):
    """Treino ativo com 2 dias; descanso curto (10seg) para o teste do timer não esperar 1 min."""
    psql(f"""
    WITH w AS (
      INSERT INTO public.workouts (id, "userId", name, "isActive")
      VALUES (gen_random_uuid(), '{user_id}', 'Treino E2E', true) RETURNING id
    ), a AS (
      INSERT INTO public.workout_days (id, "workoutId", "dayName") SELECT gen_random_uuid(), id, 'Treino A' FROM w RETURNING id
    ), b AS (
      INSERT INTO public.workout_days (id, "workoutId", "dayName") SELECT gen_random_uuid(), id, 'Treino B' FROM w RETURNING id
    )
    INSERT INTO public.exercises
      (id, "workoutDayId", nome, series, repeticoes, "modeloDeTreino", "intervaloDescanso", "progressaoDePesoSugerida")
    SELECT gen_random_uuid(), a.id, e.nome, '2', '10', 'tradicional', '10seg', 'Aumente 1kg quando completar as séries'
      FROM a, (VALUES ('Supino reto'), ('Remada curvada')) AS e(nome)
    UNION ALL
    SELECT gen_random_uuid(), b.id, e.nome, '2', '12', 'tradicional', '10seg', 'Aumente 1kg quando completar as séries'
      FROM b, (VALUES ('Agachamento livre'), ('Leg press')) AS e(nome);
    """)


def seed_subscription(user_id, email):
    """Assinatura liberada manualmente por 30 dias (mesmo status que o admin usa): sem ela a home
    bloqueia o treino."""
    psql(f"""
    INSERT INTO payment.subscriptions
      (id, reason, start_date, end_date, next_payment_date, currency_id, transaction_amount,
       date_created, last_modified, status, user_id, user_email)
    VALUES (gen_random_uuid()::text, 'E2E', now(), now() + interval '30 days', now() + interval '30 days',
       'BRL', 0, now(), now(), 'ativo manualmente', '{user_id}', '{email}');
    """)


def create_user():
    email = f"e2e-{int(time.time())}-{random.randint(100, 999)}@{EMAIL_DOMAIN}"
    session = request("POST", f"{GATEWAY}/auth/signup/start", {"email": email})["sessionId"]
    request("POST", f"{GATEWAY}/auth/signup/verify", {"sessionId": session, "code": email_code(email)})
    signup = request("POST", f"{GATEWAY}/auth/signup/complete", {"sessionId": session, "password": PASSWORD})
    token, user_id = signup["token"], signup["userId"]

    request("PUT", f"{GATEWAY}/app/onboarding/profile", {
        "name": "Usuário E2E", "gender": "Masculino", "birthDate": "15/03/1990",
        "weight": 80, "height": 178, "email": email,
    }, token)
    request("PUT", f"{GATEWAY}/app/onboarding/disclaimer", {"accepted": True, "cpf": valid_cpf()}, token)
    request("PUT", f"{GATEWAY}/app/onboarding/anamnesis", {
        "mainGoal": "ganho_massa", "hasDiseases": False, "hasPhysicalLimitations": False,
        "physicalActivityLevel": "moderado",
    }, token)
    request("PUT", f"{GATEWAY}/app/onboarding/training-preferences", {
        # 6+ dias/semana: todo dia é dia de treino (sem "Descanso" no fim de semana).
        "minTrainingDuration": 30, "maxTrainingDuration": 60, "trainingDaysPerWeek": 6,
        "wantsCardio": False, "trainingFocus": "corpo_todo",
    }, token)
    status = request("GET", f"{GATEWAY}/app/onboarding", None, token)
    if not status.get("completed"):
        sys.exit(f"onboarding do seed não concluiu: {status.get('nextStep')}")

    seed_workout(user_id)
    seed_subscription(user_id, email)
    return {"email": email, "password": PASSWORD, "userId": user_id}


def cleanup():
    """Apaga contas e emails de e2e (o domínio é exclusivo dos testes)."""
    like = f"%@{EMAIL_DOMAIN}"
    ids = psql(f"SELECT string_agg(quote_literal(id::text), ',') FROM customer.users WHERE email LIKE '{like}';")
    if ids:
        psql(f"DELETE FROM public.users WHERE id::text IN ({ids}); DELETE FROM customer.users WHERE id::text IN ({ids});")
    psql(f"DELETE FROM customer.signup_sessions WHERE email LIKE '{like}'; "
         f"DELETE FROM payment.subscriptions WHERE user_email LIKE '{like}';")
    for query in (f"to:{EMAIL_DOMAIN}", "to:sms.local"):
        urllib.request.urlopen(urllib.request.Request(
            f"{MAILPIT}/api/v1/search?query={urllib.parse.quote(query)}", method="DELETE"), timeout=10)


if __name__ == "__main__":
    if "--cleanup" in sys.argv:
        cleanup()
    else:
        print(json.dumps(create_user()))
