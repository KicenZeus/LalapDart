import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/config/app_config.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String? token;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.fileUrl,
    this.token,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int _rotationQuarterTurns = 0;
  late final PhotoViewController _photoViewController;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _zoomIn() {
    final currentScale = _photoViewController.scale ?? 1.0;
    _photoViewController.scale = (currentScale * 1.3).clamp(0.5, 5.0);
  }

  void _zoomOut() {
    final currentScale = _photoViewController.scale ?? 1.0;
    _photoViewController.scale = (currentScale / 1.3).clamp(0.5, 5.0);
  }

  void _resetZoom() {
    _photoViewController.reset();
    setState(() {
      _rotationQuarterTurns = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bangun URL lengkap dengan parameter token jika ada
    String fullUrl = widget.fileUrl.startsWith('http')
        ? widget.fileUrl
        : '${AppConfig.apiBaseUrl.replaceAll('/api', '')}${widget.fileUrl}';

    if (widget.token != null && widget.token!.isNotEmpty) {
      final sep = fullUrl.contains('?') ? '&' : '?';
      fullUrl = '$fullUrl${sep}token=${widget.token}';
    }

    final rotationDegrees = _rotationQuarterTurns * 90;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            if (rotationDegrees > 0)
              Text(
                'Rotasi: $rotationDegrees°',
                style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perbesar (+)',
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
          ),
          IconButton(
            tooltip: 'Perkecil (-)',
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
          IconButton(
            tooltip: 'Putar 90°',
            icon: const Icon(Icons.rotate_right),
            onPressed: _rotateClockwise,
          ),
          IconButton(
            tooltip: 'Reset Zoom & Rotasi',
            icon: const Icon(Icons.refresh),
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: RotatedBox(
                quarterTurns: _rotationQuarterTurns,
                child: PhotoView(
                  controller: _photoViewController,
                  imageProvider: NetworkImage(fullUrl),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: fullUrl),
                  loadingBuilder: (context, event) => Center(
                    child: CircularProgressIndicator(
                      value: event == null || event.expectedTotalBytes == null
                          ? null
                          : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                      color: Colors.white,
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal memuat pratinjau dokumen.\nPastikan server backend aktif.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                            label: const Text('Coba Lagi', style: TextStyle(color: Colors.blueAccent)),
                            onPressed: () {
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Hint Gestur di bagian bawah layar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Pinch untuk Zoom hingga 4x • Geser • Tombol Putar 90°',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
