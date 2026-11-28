import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

import '../../l10n/app_localizations.dart';
import 'qr_image_saver.dart';

Future<void> showConfigQrDialog(
  BuildContext context, {
  required String data,
  required String description,
}) async {
  final QrImage qrImage;
  try {
    final code = QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.low,
    );
    qrImage = QrImage(code);
  } on InputTooLongException {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.qrTooLargeTitle),
        content: Text(l10n.qrTooLargeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
    return;
  }

  if (!context.mounted) return;
  final qrSize = (MediaQuery.sizeOf(context).width - 180)
      .clamp(140.0, 260.0)
      .toDouble();
  await showDialog<void>(
    context: context,
    builder: (context) => _QrExportDialog(
      image: qrImage,
      description: description,
      qrSize: qrSize,
    ),
  );
}

class _QrExportDialog extends StatefulWidget {
  const _QrExportDialog({
    required this.image,
    required this.description,
    required this.qrSize,
  });

  final QrImage image;
  final String description;
  final double qrSize;

  @override
  State<_QrExportDialog> createState() => _QrExportDialogState();
}

class _QrExportDialogState extends State<_QrExportDialog> {
  bool _saving = false;
  String? _message;
  bool _failed = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _message = null;
      _failed = false;
    });
    try {
      final saved = await saveQrImage(
        widget.image,
        typeLabel: l10n.pngImageFileType,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (saved) _message = l10n.qrSaved;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failed = true;
        _message = l10n.qrSaveFailed('$error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.qrExportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Semantics(
                label: l10n.qrSemanticsLabel,
                image: true,
                child: CustomPaint(
                  size: Size.square(widget.qrSize),
                  painter: _QrPainter(widget.image),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.qrScanInstruction,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.qrSecretWarning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _failed
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.qrSaveLocally),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final cellSize = size.shortestSide / image.moduleCount;
    final darkPaint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var column = 0; column < image.moduleCount; column++) {
        if (image.isDark(row, column)) {
          canvas.drawRect(
            Rect.fromLTWH(
              column * cellSize,
              row * cellSize,
              cellSize + 0.01,
              cellSize + 0.01,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.image != image;
}
