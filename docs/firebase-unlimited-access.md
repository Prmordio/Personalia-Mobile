# Acesso ilimitado por e-mail (Firebase Remote Config)

Libera as áreas de assinante do app (abas Relatórios, Indicação, Menu, chat e cards de treino)
para e-mails específicos **sem** criar assinatura — ex.: a conta demo da revisão da Apple.
A assinatura real não muda: o botão "Assinar" e a compra pela loja continuam disponíveis,
para o revisor conseguir testar o In-App Purchase.

Código: `lib/features/home/state/feature_access.dart` (`featureAccessProvider`).

> Só o app é liberado. Regras do backend que exigem assinatura (ex.: gerar treino novo)
> continuam valendo para essas contas.

## Por que hash

O Remote Config é baixado por qualquer instalação do app, então a lista é pública.
Guardamos só o SHA-256 do e-mail (minúsculo, sem espaços), nunca o e-mail em texto.

## Passo a passo no Firebase

1. Firebase Console → projeto do PersonaliA → **Run → Remote Config**.
2. **Add parameter**:
   - Parameter name: `unlimited_access_email_hashes`
   - Data type: **String**
   - Default value: os hashes, separados por vírgula (ou espaço/quebra de linha).
3. **Save** e depois **Publish changes** (sem publicar, o app não recebe).

Valor atual (conta demo da revisão da Apple, `contatoprmordio@gmail.com`):

```
5c71ee4b652a59e2b2478a978874ee4d219daf810cbcd88a4f9d966a4daa3348
```

## Gerar o hash de outro e-mail

```bash
printf '%s' 'Email@Exemplo.com' | tr '[:upper:]' '[:lower:]' | sha256sum
```

Use só a parte hexadecimal (64 caracteres). Para vários e-mails:
`hash1,hash2,hash3`.

## Quando a mudança chega no app

- O app busca o Remote Config ao abrir o shell e guarda por até **1 hora**
  (`minimumFetchInterval`). Para testar na hora, feche e reabra o app depois desse tempo
  ou reinstale.
- Sem rede, vale o último valor recebido; sem valor nenhum, ninguém é liberado.

## Remover o acesso

Apague o hash do parâmetro e publique. A conta volta a ficar bloqueada sem assinatura
na próxima busca do Remote Config (até 1 hora).

## Checklist antes de enviar para revisão da Apple

- [ ] Parâmetro `unlimited_access_email_hashes` publicado com o hash da conta demo.
- [ ] Conta demo continua **sem** assinatura ativa (senão a compra fica bloqueada).
- [ ] Conta demo listada em `STORE_BILLING_SANDBOX_ALLOWED_EMAILS` no ConfigMap do
      `payment-api` (aceita compra sandbox em produção — ver `k8s/STORE-NOTIFICATIONS.md`).
- [ ] Testado no TestFlight logado com a conta demo: abas liberadas e "Assinar" visível.
