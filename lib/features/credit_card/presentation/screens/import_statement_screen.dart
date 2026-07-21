import 'package:flutter/material.dart';
import '../../../../presentation/widgets/custom_snackbar.dart';

class ImportStatementScreen extends StatefulWidget {
  const ImportStatementScreen({super.key});

  @override
  State<ImportStatementScreen> createState() => _ImportStatementScreenState();
}

class _ImportStatementScreenState extends State<ImportStatementScreen> {
  String _selectedFileType = 'CSV';
  bool _isProcessing = false;

  void _onImportFile() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isProcessing = false);
      AppSnackBar.show(
        context,
        message: 'Statement parsed successfully! 14 purchases & 2 payments reconciled.',
        isError: false,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Bank Statement', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('Upload Credit Card Statement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports CSV, Excel, and PDF files. Auto-detects purchases, payments, refunds, and cashback with duplicate detection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('SELECT STATEMENT FORMAT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFormatChip('CSV'),
                _buildFormatChip('Excel (.xlsx)'),
                _buildFormatChip('PDF'),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.file_open),
              label: Text(_isProcessing ? 'Processing Statement...' : 'Choose File to Import', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isProcessing ? null : _onImportFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format) {
    final isSelected = _selectedFileType == format;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(format, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primaryColor)),
      selected: isSelected,
      selectedColor: primaryColor,
      onSelected: (val) {
        if (val) setState(() => _selectedFileType = format);
      },
    );
  }
}
