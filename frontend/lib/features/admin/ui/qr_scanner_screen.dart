import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/admin/services/admin_service.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/shared/widgets/animated_toast.dart';
import 'package:go_router/go_router.dart';

class QRScannerScreen extends StatefulWidget {
  final String eventId;

  const QRScannerScreen({super.key, required this.eventId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        await _processCheckin(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processCheckin(String registrationId) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final apiClient = ApiClient();
      final adminService = AdminService(apiClient.dio);
      await adminService.checkinAttendee(widget.eventId, registrationId);
      
      if (!mounted) return;
      AnimatedToast.show(context, message: 'Check-in successful!', isError: false);
      // Let the user scan another ticket or close manually
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Failed to check-in';
      if (e is ApiException) {
        errorMsg = e.message;
      }
      AnimatedToast.show(context, message: errorMsg, isError: true);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Entry'),
          content: TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              labelText: 'Registration ID',
              hintText: 'Enter the registration ID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_manualController.text.isNotEmpty) {
                  _processCheckin(_manualController.text);
                }
              },
              child: const Text('Check In'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _showManualEntryDialog,
                icon: const Icon(Icons.keyboard),
                label: const Text('Manual Entry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
