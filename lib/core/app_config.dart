/// Número do bot PersonalIA no WhatsApp (só dígitos, com DDI). Público — o mesmo exibido no site.
/// Para apontar para o número de testes:
///   flutter run --dart-define=WHATSAPP_BOT_NUMBER=5511999999999
const whatsappBotNumber = String.fromEnvironment('WHATSAPP_BOT_NUMBER', defaultValue: '15556134265');

/// Texto pré-preenchido no WhatsApp para pedir o código de acesso ao app. O trainer reconhece
/// o trecho "código de acesso" (ver HandleAppAccessCodeRequestUseCase) — manter em sincronia.
const appAccessWhatsAppMessage = 'Quero meu código de acesso ao app PersonalIA';
