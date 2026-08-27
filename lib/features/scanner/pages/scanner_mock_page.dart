import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';

class ScannerMockPage extends StatefulWidget {
  const ScannerMockPage({super.key});

  @override
  State<ScannerMockPage> createState() => _ScannerMockPageState();
}

class _ScannerMockPageState extends State<ScannerMockPage> with SingleTickerProviderStateMixin {
  bool _isFlashOn = false;
  bool _isAutoCropOn = true;
  bool _isBatchMode = false;
  int _batchCount = 0;

  late AnimationController _scannerLineController;
  late Animation<double> _scannerLineAnimation;

  @override
  void initState() {
    super.initState();
    _scannerLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerLineAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scannerLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerLineController.dispose();
    super.dispose();
  }

  void _captureScan() {
    if (_isBatchMode) {
      setState(() {
        _batchCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Captured page $_batchCount in batch.'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      _processScanSingle();
    }
  }

  void _processScanSingle() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Simulate progression
            Future.delayed(const Duration(milliseconds: 800), () {
              if (context.mounted) {
                Get.find<ScanController>().addScan(
                  "mock_scanned_file.pdf",
                  customName: "Scan_${DateTime.now().millisecondsSinceEpoch}.pdf",
                  fileType: "PDF",
                );
                Get.back(); // Close dialog
                Get.back(); // Go back from Scanner
                Get.rawSnackbar(
                  messageText: const Text(
                    'Document scanned successfully! Cleaned up by AI.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12),
                  borderRadius: 8,
                );
              }
            });

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing Document...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAutoCropOn ? 'Detecting edges & cropping...' : 'Optimizing color details...',
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _finishBatch() {
    if (_batchCount == 0) {
      Get.back();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            for (int i = 1; i <= _batchCount; i++) {
              Get.find<ScanController>().addScan(
                "mock_batch_page_$i.jpg",
                customName: "BatchScan_${DateTime.now().millisecondsSinceEpoch}_Page$i.jpg",
                fileType: "JPG",
              );
            }
            Get.back(); // Close dialog
            Get.back(); // Go back from Scanner
            Get.rawSnackbar(
              messageText: Text(
                'Batch scan complete: $_batchCount pages processed & saved!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.primary,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(12),
              borderRadius: 8,
            );
          }
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Processing Batch...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applying AI Enhancement to $_batchCount pages...',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: _isFlashOn ? AppColors.amber : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isAutoCropOn ? Icons.crop_outlined : Icons.crop_din,
                          color: _isAutoCropOn ? AppColors.blue : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isAutoCropOn = !_isAutoCropOn;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isAutoCropOn ? 'Auto-Crop Enabled' : 'Auto-Crop Disabled (Manual)'),
                              duration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Camera View Simulation Frame
            Expanded(
              child: Stack(
                children: [
                  // Camera Simulation Background
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          // Grid backdrop lines
                          Positioned.fill(
                            child: GridPaper(
                              color: Colors.white.withOpacity(0.03),
                              divisions: 2,
                              subdivisions: 2,
                              interval: 100,
                            ),
                          ),
                          // Simulated document sheet laying flat
                          Center(
                            child: Container(
                              width: 250,
                              height: 350,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(4, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 80, height: 12, color: Colors.indigo.shade300),
                                  const SizedBox(height: 12),
                                  Container(width: 200, height: 8, color: Colors.grey.shade400),
                                  const SizedBox(height: 6),
                                  Container(width: 170, height: 8, color: Colors.grey.shade400),
                                  const SizedBox(height: 6),
                                  Container(width: 190, height: 8, color: Colors.grey.shade400),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: 50, height: 10, color: Colors.grey.shade400),
                                      Container(width: 30, height: 10, color: Colors.indigo.shade300),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Smart Edge Detection Border guide (If enabled)
                          if (_isAutoCropOn)
                            Positioned(
                              left: 40,
                              right: 40,
                              top: 60,
                              bottom: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.blue.withOpacity(0.8),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    // Corners indicators
                                    _buildCornerIndicator(Alignment.topLeft),
                                    _buildCornerIndicator(Alignment.topRight),
                                    _buildCornerIndicator(Alignment.bottomLeft),
                                    _buildCornerIndicator(Alignment.bottomRight),
                                  ],
                                ),
                              ),
                            ),

                          // Bouncing laser light bar simulator
                          AnimatedBuilder(
                            animation: _scannerLineAnimation,
                            builder: (context, child) {
                              return Positioned(
                                left: 20,
                                right: 20,
                                top: MediaQuery.of(context).size.height * 0.6 * _scannerLineAnimation.value,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue.withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Helper prompt
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.crop_free, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hold steady. Detecting edges...',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mode Selector: Single vs Batch
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBatchMode = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isBatchMode ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SINGLE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBatchMode = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isBatchMode ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BATCH SCAN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Shutter Panel
            Container(
              padding: const EdgeInsets.only(bottom: 32, top: 16, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Photo gallery shortcut mock
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.photo_outlined, color: Colors.white),
                  ),

                  // Capture Button
                  GestureDetector(
                    onTap: _captureScan,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Batch Finish or Import button
                  GestureDetector(
                    onTap: _finishBatch,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isBatchMode && _batchCount > 0 ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: _isBatchMode && _batchCount > 0
                            ? Text(
                                '$_batchCount',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : const Icon(Icons.file_upload_outlined, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.blue, width: 2),
        ),
      ),
    );
  }
}
