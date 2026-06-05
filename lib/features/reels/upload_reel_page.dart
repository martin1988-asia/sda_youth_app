// ================= IMPORTS =================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ================= WIDGET =================
class UploadReelPage extends StatefulWidget {
  final XFile? videoFile;
  final XFile? imageFile;

  const UploadReelPage({super.key, this.videoFile, this.imageFile});

  @override
  State<UploadReelPage> createState() => _UploadReelPageState();
}

// ================= STATE =================
class _UploadReelPageState extends State<UploadReelPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _video;
  final TextEditingController caption = TextEditingController();

  bool _uploading = false;
  double _progress = 0;

  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  double _brightness = 1.0;
  double _contrast = 1.0;

  String _selectedMusic = "None";
  late AnimationController _anim;

  // ✅ MEDIA TYPE DETECTION (CRITICAL FIX)
  bool get isVideo {
    final file = widget.videoFile;

    return file != null && (file.mimeType?.startsWith("video") ?? false);
  }

  // ✅ TIMELINE DATA
  final List<Uint8List> _thumbnails = [];

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    if (widget.videoFile != null) {
      if (kIsWeb) {
        _video = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoFile!.path),
        );
      } else {
        _video = VideoPlayerController.file(File(widget.videoFile!.path));
      }

      _video.initialize().then((_) {
        _video.setLooping(true);
        _video.play();
        _video.addListener(_handleTrimLoop);

        _generateThumbnails(); // ✅ NOW GENERATES REAL FRAMES

        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    if (widget.videoFile != null) {
      _video.removeListener(_handleTrimLoop);
      _video.dispose();
    }
    _anim.dispose();
    caption.dispose();
    super.dispose();
  }

  // ================= THUMBNAILS =================
  Future<void> _generateThumbnails() async {
    if (!_video.value.isInitialized) return;

    // ⚠️ Web fallback (no real thumbnails on web)
    if (kIsWeb) return;

    final videoPath = widget.videoFile!.path;

    _thumbnails.clear();

    const count = 8;
    final duration = _video.value.duration.inMilliseconds;

    final futures = List.generate(count, (i) async {
      final ms = (duration * (i / count)).toInt();

      final bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: ms,
        quality: 50,
      );

      return bytes;
    });

    final results = await Future.wait(futures);

    _thumbnails.clear();

    for (var bytes in results) {
      if (bytes != null) {
        _thumbnails.add(bytes);
      }
    }

    if (mounted) setState(() {});
  }

  // ================= MUSIC =================
  void _pickMusic() {
    final tracks = ["None", "Afro Beat", "Amapiano", "Gospel"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return ListView(
          children: tracks.map((t) {
            return ListTile(
              title: Text(t, style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _selectedMusic = t);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

// ================= UPLOAD =================
Future<void> upload() async {
  if (_uploading) return;

  setState(() {
    _uploading = true;
    _progress = 0;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final file = widget.videoFile ?? widget.imageFile;
    if (file == null) return;

    final fileName =
        "reels/${user.uid}_${DateTime.now().millisecondsSinceEpoch}";

    final ref = FirebaseStorage.instance.ref().child(fileName);

    final bytes = await file.readAsBytes();

    final uploadTask = ref.putData(bytes);

    // ✅ TRACK PROGRESS
    uploadTask.snapshotEvents.listen((event) {
      if (!mounted) return;

      setState(() {
        _progress = event.bytesTransferred /
            (event.totalBytes == 0 ? 1 : event.totalBytes);
      });
    });

    await uploadTask;

    final url = await ref.getDownloadURL();

    // ✅ GET USER INFO FROM FIRESTORE (IMPORTANT FIX 🔥)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    // ✅ SAVE REEL
    await FirebaseFirestore.instance.collection('reels').add({
      'mediaUrl': url,
      'userId': user.uid,
      'userName': userData['name'] ?? 'User',
      'userPhotoUrl': userData['userPhotoUrl'] ?? '',
      'caption': caption.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'type': isVideo ? 'video' : 'image',

      // ✅ engagement fields
      'reactionsCount': 0,
      'commentsCount': 0,
      'score': 0,
      'totalWatchTime': 0,
      'skipCount': 0,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reel uploaded ✅")),
    );

    Navigator.pop(context);

  } catch (e) {
    debugPrint("UPLOAD ERROR: $e");

    if (!mounted) return;

    setState(() => _uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
    );
  }
}


  // ================= PLAY =================
  void _togglePlay() {
    if (widget.videoFile == null) return;
    _video.value.isPlaying ? _video.pause() : _video.play();
  }

  // ✅ ADD LOOP FUNCTION HERE
  void _handleTrimLoop() {
    if (!_video.value.isInitialized) return;

    final pos = _video.value.position;
    final duration = _video.value.duration;

    if (duration.inMilliseconds == 0) return;

    final start = Duration(
      milliseconds: (duration.inMilliseconds * _trimStart).toInt(),
    );

    final end = Duration(
      milliseconds: (duration.inMilliseconds * _trimEnd).toInt(),
    );

    // ✅ LOOP BACK
    if (pos >= end) {
      _video.seekTo(start);
      _video.play();
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Create Reel"),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _uploading ? null : upload,
            child: _uploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Post", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),

      body: Stack(
        children: [
          // ✅ VIDEO / IMAGE PREVIEW (FIXED CLEAN VERSION)
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _togglePlay,
              child: Builder(
                builder: (_) {
                  // ✅ VIDEO (ONLY IF TRUE VIDEO — PRIORITY FIRST)
                  if (isVideo && widget.videoFile != null) {
                    if (_video.value.isInitialized && !_video.value.hasError) {
                      return VideoPlayer(_video);
                    } else {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              "Loading video...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  // ✅ IMAGE (ONLY IF NOT VIDEO — STRICT)
                  if (!isVideo && widget.imageFile != null) {
                    if (kIsWeb) {
                      return Image.network(
                        widget.imageFile!.path,
                        fit: BoxFit.cover,
                      );
                    } else {
                      return Image.file(
                        File(widget.imageFile!.path),
                        fit: BoxFit.cover,
                      );
                    }
                  }

                  // ✅ FALLBACK
                  return const Center(
                    child: Text(
                      "No media selected",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),

          // ✅ CONTROLS OVERLAY (FULL CORRECT)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 330,
              color: Colors.black.withValues(alpha: 0.85),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ TIMELINE
                    if (widget.videoFile != null && _video.value.isInitialized)
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // ✅ THUMBNAILS
                                ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: kIsWeb ? 8 : _thumbnails.length,
                                  itemBuilder: (context, index) {
                                    final hasThumb =
                                        index < _thumbnails.length && !kIsWeb;

                                    return Container(
                                      width: 70,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: hasThumb
                                          ? Image.memory(
                                              _thumbnails[index],
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.black54,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                    );
                                  },
                                ),

                                // ✅ PLAYHEAD (SAFE VERSION)
                                Positioned.fill(
                                  child: Builder(
                                    builder: (context) {
                                      final duration =
                                          _video.value.duration.inMilliseconds;

                                      if (duration == 0) {
                                        return Container(); // ✅ prevent crash
                                      }

                                      final progress =
                                          _video.value.position.inMilliseconds /
                                          duration;

                                      return Align(
                                        alignment: Alignment(
                                          (progress * 2) - 1,
                                          0,
                                        ),
                                        child: Container(
                                          width: 2,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // ✅ SCRUB
                    if (widget.videoFile != null &&
                        _video.value.isInitialized &&
                        _video.value.duration.inMilliseconds > 0)
                      Slider(
                        value:
                            (_video.value.position.inMilliseconds /
                                    _video.value.duration.inMilliseconds)
                                .clamp(0.0, 1.0),
                        onChanged: (v) {
                          final pos = v * _video.value.duration.inMilliseconds;

                          _video.seekTo(Duration(milliseconds: pos.toInt()));
                        },
                      ),

                    // ✅ TRIM
                    RangeSlider(
                      values: RangeValues(_trimStart, _trimEnd),
                      onChanged: (v) {
                        setState(() {
                          _trimStart = v.start;
                          _trimEnd = v.end;
                        });
                      },
                    ),

                    // ✅ BRIGHTNESS
                    Slider(
                      value: _brightness,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (v) => setState(() => _brightness = v),
                    ),

                    // ✅ CONTRAST
                    Slider(
                      value: _contrast,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (v) => setState(() => _contrast = v),
                    ),

                    // ✅ MUSIC
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                        title: Text(
                          _selectedMusic,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: _pickMusic,
                      ),
                    ),

                    // ✅ CAPTION
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: caption,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Write caption...",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),

                    // ✅ UPLOAD PROGRESS
                    if (_uploading) LinearProgressIndicator(value: _progress),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
