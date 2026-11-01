#!/usr/bin/env python3
"""Cria o usuário dos testes integrados do app (integration_test/) no ambiente local.

Cadastro e onboarding passam pela API real do gateway (código do email lido no Mailpit); só o
treino é inserido por SQL, para os testes não dependerem da geração pelo agent-v2 (lenta, gasta
LLM e muda a cada execução). Pelo mesmo motivo as alternativas da troca de exercício do
"Puxada E2E" vão direto para o cache do agent-v2 (Redis), que responde sem chamar a IA.
Imprime em JSON as credenciais que o run.sh repassa ao app.

Uso: seed_user.py [--cleanup]   (--cleanup apaga todos os usuários e emails de e2e)

O usuário sai com assinatura válida por 30 dias (conferida pela API antes de devolver).
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
# Exercício exclusivo dos testes: o cache de alternativas é global (nome + objetivo), então um
# nome real ("Remada curvada") faria o ambiente de dev inteiro receber as alternativas fixas.
SWAP_EXERCISE = "Puxada E2E"
SWAP_ALTERNATIVES = [
    {"nome": "Puxada aberta E2E", "series": "3", "repeticoes": "10-12"},
    {"nome": "Remada baixa E2E", "series": "3", "repeticoes": "12"},
]


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
      FROM b, (VALUES ('Agachamento livre'), ('Leg press'), ('{SWAP_EXERCISE}')) AS e(nome);
    """)


def redis(*args):
    password = subprocess.run(COMPOSE + ["exec", "-T", "agent-v2", "printenv", "REDIS_PASSWORD"],
                              capture_output=True, text=True).stdout.strip()
    result = subprocess.run(COMPOSE + ["exec", "-T", "redis", "redis-cli", "-a", password, "--no-auth-warning", *args],
                            capture_output=True, text=True)
    if result.returncode != 0 or result.stdout.startswith(("ERR", "WRONGPASS", "NOAUTH")):
        sys.exit(f"redis falhou: {result.stdout}{result.stderr}")
    return result.stdout.strip()


def alternatives_key(goal):
    """Mesma chave do agent-v2 (CacheManager._alternatives_cache_key) para exercício de força."""
    return f"alternatives:{SWAP_EXERCISE.lower()}:{goal.lower().strip()}:strength"


def seed_alternatives(user_id):
    goal = psql(f"""SELECT "mainGoal" FROM public.anamnesis WHERE "userId" = '{user_id}';""")
    redis("SETEX", alternatives_key(goal), str(7 * 24 * 3600), json.dumps(SWAP_ALTERNATIVES, ensure_ascii=False))


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
    seed_alternatives(user_id)
    seed_subscription(user_id, email)
    check_ready(token)
    return {"email": email, "password": PASSWORD, "userId": user_id}


def check_ready(token):
    """Confere pela API o que os testes assumem. Um serviço caído (payment-api, agent-v2) não
    derruba o container nem o gateway, e o teste só falharia minutos depois, numa tela errada."""
    subscription = request("GET", f"{GATEWAY}/app/subscription", None, token)
    if not subscription.get("isValid"):
        sys.exit(f"assinatura do seed não validou ({subscription}) — o payment-api está de pé? "
                 "make restart-service S=payment-api")
    alternatives = request("POST", f"{GATEWAY}/app/workout/exercise/alternatives",
                           {"exerciseName": SWAP_EXERCISE, "series": "2", "reps": "12", "isCardio": False}, token)
    names = [a.get("nome") for a in alternatives.get("alternatives", [])]
    if names != [a["nome"] for a in SWAP_ALTERNATIVES]:
        sys.exit(f"alternativas fixas não vieram do cache ({names}) — o agent-v2 e o redis estão de pé?")


def cleanup():
    """Apaga contas e emails de e2e (o domínio é exclusivo dos testes)."""
    like = f"%@{EMAIL_DOMAIN}"
    ids = psql(f"SELECT string_agg(quote_literal(id::text), ',') FROM customer.users WHERE email LIKE '{like}';")
    if ids:
        psql(f"DELETE FROM public.users WHERE id::text IN ({ids}); DELETE FROM customer.users WHERE id::text IN ({ids});")
    psql(f"DELETE FROM customer.signup_sessions WHERE email LIKE '{like}'; "
         f"DELETE FROM payment.subscriptions WHERE user_email LIKE '{like}';")
    for key in redis("--scan", "--pattern", alternatives_key("*")).split():
        redis("DEL", key)
    for query in (f"to:{EMAIL_DOMAIN}", "to:sms.local"):
        urllib.request.urlopen(urllib.request.Request(
            f"{MAILPIT}/api/v1/search?query={urllib.parse.quote(query)}", method="DELETE"), timeout=10)


if __name__ == "__main__":
    if "--cleanup" in sys.argv:
        cleanup()
    else:
        print(json.dumps(create_user()))
