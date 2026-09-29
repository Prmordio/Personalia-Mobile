import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/reports_api.dart';

/// Gera o PDF no servidor e abre a folha de compartilhar do sistema (salvar, abrir, enviar).
Future<void> sharePdfReport(BuildContext context, WidgetRef ref, ReportPdf report) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Gerando PDF...'), duration: Duration(seconds: 2)));
  try {
    final bytes = await ref.read(reportsApiProvider).downloadPdf(report);
    final fileName = 'personalia_${report.type}.pdf';
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
      fileNameOverrides: [fileName],
    );
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Não foi possível gerar o PDF. Tente novamente.')));
  }
}

/// Estrutura comum das telas de relatório: título, botão de PDF, puxar para atualizar,
/// carregando/erro e estado vazio.
class ReportScaffold<T> extends ConsumerWidget {
  const ReportScaffold({
    super.key,
    required this.title,
    required this.provider,
    required this.builder,
    this.pdf,
    this.isEmpty,
    this.emptyMessage = 'Ainda não há dados para este relatório.',
  });

  final String title;
  final ProviderBase<AsyncValue<T>> provider;
  final List<Widget> Function(BuildContext context, T data) builder;
  final ReportPdf? pdf;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (pdf != null)
            IconButton(
              tooltip: 'Baixar PDF',
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => sharePdfReport(context, ref, pdf!),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(provider),
        child: async.when(
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: isEmpty?.call(data) == true ? [_EmptyState(message: emptyMessage)] : builder(context, data),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('Não foi possível carregar o relatório. Puxe para tentar de novo.', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Card com título usado nas seções dos relatórios.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
