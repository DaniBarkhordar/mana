/// Barcode capture. The camera does one job here — read the code — and the
/// lookup, cache and fallback all happen in the search sheet that opened it.
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/tokens.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  /// Opens the scanner and returns the first retail barcode seen, or null.
  static Future<String?> scan(BuildContext context) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          fullscreenDialog: true,
          builder: (_) => const BarcodeScanScreen(),
        ),
      );

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  // Retail codes only: EAN and UPC. QR codes on packaging point at marketing
  // sites, not products, and would send the lookup nowhere useful.
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final code = b.rawValue;
      if (code != null && RegExp(r'^\d{6,14}$').hasMatch(code)) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a barcode')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // A window the size of a typical pack barcode, so people know where
          // to hold it.
          Center(
            child: Container(
              width: 260,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: MananuColors.brass, width: 2),
                borderRadius: MananuSpacing.radiusMd,
              ),
            ),
          ),
          Positioned(
            left: MananuSpacing.xl,
            right: MananuSpacing.xl,
            bottom: MananuSpacing.huge,
            child: Text(
              'Hold the barcode inside the frame. Barcode lookup is free and '
              'stays free.',
              textAlign: TextAlign.center,
              style: MananuType.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
