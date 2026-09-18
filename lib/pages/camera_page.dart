import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Full-screen selfie capture. Front camera by default, square framing
/// guide overlay, captures and pops the [XFile] straight back —
/// no retake/confirm step (upload happens immediately on the caller side).
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _capturing = false;
  String? _error;
  XFile? _preview;

  @override
  void initState() {
    super.initState();
    _initFuture = _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = 'No camera found on this device.';
        return;
      }
      final front = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      _controller = controller;
    } catch (e) {
      _error = 'Unable to access the camera.';
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _preview = file;
        _capturing = false;
      });
    } catch (e) {
      setState(() => _capturing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to capture photo.')),
      );
    }
  }

  void _retake() {
    setState(() => _preview = null);
  }

  void _confirm() {
    final file = _preview;
    if (file == null) return;
    Navigator.of(context).pop(file);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (_error != null || _controller == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? 'Camera unavailable.',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final controller = _controller!;
          final isFront =
              controller.description.lensDirection ==
                  CameraLensDirection.front;

          if (_preview != null) {
            return _buildReview(_preview!);
          }
          return _buildLivePreview(_controller!);
        },
      ),
    );
  }

  Widget _buildLivePreview(CameraController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side =
                  (constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight) *
                      0.8;
              return Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: side,
                        height: side * controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Palette.primary,
                      width: 3,
                    ),
                  ),
                  child: _capturing
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.primary,
                    ),
                  )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(XFile file) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14159),
              child: Image.file(File(file.path), fit: BoxFit.cover),
            )
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ReviewButton(icon: Icons.refresh, label: 'Retake', onTap: _retake),
                  const SizedBox(width: 32),
                  _ReviewButton(icon: Icons.check, label: 'Use photo', onTap: _confirm, filled: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Palette.primary : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: filled ? null : Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}