import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/ocr_service.dart';
import 'custom_snackbar.dart';

class ScannerPreviewDialog extends StatefulWidget {
  final Function(double amount, String merchant, DateTime date) onScanCompleted;

  const ScannerPreviewDialog({
    super.key,
    required this.onScanCompleted,
  });

  static void show(
    BuildContext context, {
    required Function(double amount, String merchant, DateTime date) onScanCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScannerPreviewDialog(onScanCompleted: onScanCompleted),
    );
  }

  @override
  State<ScannerPreviewDialog> createState() => _ScannerPreviewDialogState();
}

class _ScannerPreviewDialogState extends State<ScannerPreviewDialog> {
  final _picker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;

  // Editable parsed values
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        // Smaller resolution = faster OCR with no meaningful accuracy loss.
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isLoading = true;
      });

      await _performOcr(_selectedImage!);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Failed to access camera or gallery: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _performOcr(File file) async {
    // Use the singleton OcrService – TextRecognizer is reused, parsing is
    // offloaded to a background isolate, keeping the UI fully responsive.
    final parsed = await OcrService.instance.processImage(file.path);

    if (!mounted) return;
    setState(() {
      _merchantController.text = parsed.merchant == 'Unknown Merchant' ? '' : parsed.merchant;
      _amountController.text = parsed.amount > 0 ? parsed.amount.toStringAsFixed(2) : '';
      _selectedDate = parsed.date;
      _isLoading = false;
    });

    if (parsed.amount == 0.0 && parsed.merchant == 'Unknown Merchant') {
      AppSnackBar.show(
        context,
        message: 'Scan complete. Could not auto-detect amount or merchant — please fill in manually.',
        isError: false,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _apply() {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    final merchant = _merchantController.text.trim();

    if (amt <= 0) {
      AppSnackBar.show(
        context,
        message: 'Please enter a valid amount before applying',
        isError: true,
      );
      return;
    }

    widget.onScanCompleted(amt, merchant.isEmpty ? 'Unknown Merchant' : merchant, _selectedDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final keyboardOffset = MediaQuery.of(context).viewInsets.bottom;


    final sheetBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final itemBgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: 24 + keyboardOffset,
      ),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slide indicator
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.document_scanner_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Scan Bill / Screenshot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_selectedImage == null) ...[
              // Setup Options View
              Text(
                'Import a payment success screen or snap a physical receipt to auto-fill details locally.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Camera Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('From Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_isLoading) ...[
              // Loading Scanning view
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'AI Scanning Image Details...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Extracting amount, merchant, and dates offline',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Scanned Results View
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: itemBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'REVIEW EXTRACTED DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Merchant Field
                    TextField(
                      controller: _merchantController,
                      decoration: InputDecoration(
                        labelText: 'Payee / Merchant',
                        prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount Paid',
                        prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Row
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDarkMode ? Colors.white30 : Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('MMMM dd, yyyy').format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: borderColor),
                    ),
                    child: const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply & Auto-fill',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
