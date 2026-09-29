import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout/presentation/widgets/exercise_video_sheet.dart';
import '../state/assistant_chat_controller.dart';

/// Chat de dúvidas (botão flutuante). [openCameraOnStart] = atalho "Pesquisar máquina":
/// abre a câmera direto e manda a foto para identificar o aparelho.
class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key, this.openCameraOnStart = false});
  final bool openCameraOnStart;

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.openCameraOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto(ImageSource.camera));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(assistantChatProvider.notifier).send(text);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Reduz antes de enviar: o Gemini não precisa de foto em resolução máxima.
      final file = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = file.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      await ref.read(assistantChatProvider.notifier).sendPhoto(bytes, mime);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível acessar a câmera/galeria. Verifique as permissões.')),
      );
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto do aparelho'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(assistantChatProvider);
    final waiting = messages.isNotEmpty && messages.last.pending;

    // Nova mensagem → rola para o fim.
    ref.listen(assistantChatProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tire suas dúvidas'),
        actions: [
          TextButton.icon(
            onPressed: waiting ? null : () => _pickPhoto(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Pesquisar máquina'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) => _Bubble(message: messages[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Enviar foto de aparelho',
                    onPressed: waiting ? null : _choosePhotoSource,
                    icon: const Icon(Icons.add_a_photo_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Escreva sua dúvida...', counterText: ''),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: waiting ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: message.image != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.orange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: message.pending
            ? const _TypingDots()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(message.image!, width: 220, fit: BoxFit.cover),
                    ),
                  if (message.text.isNotEmpty) Text(message.text, style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                  if (message.exerciseName != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => showExerciseVideoSheet(context, exerciseName: message.exerciseName!),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Ver vídeos de execução'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CircleAvatar(radius: 4, backgroundColor: i == active ? Colors.grey : Colors.grey.shade300),
              ),
          ],
        );
      },
    );
  }
}
