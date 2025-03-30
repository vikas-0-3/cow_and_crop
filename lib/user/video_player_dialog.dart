import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;
  const VideoPlayerDialog({Key? key, required this.videoPath})
    : super(key: key);

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController; // Make ChewieController nullable
  bool _initialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    _videoPlayerController
        .initialize()
        .then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: false,
          );
          setState(() {
            _initialized = true;
          });
        })
        .catchError((error) {
          // Log the error for debugging and set an error message.
          print("Error initializing video: $error");
          setState(() {
            _errorMessage = error.toString();
          });
        });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose(); // Dispose only if it's not null.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error loading video: $_errorMessage"),
        ),
      );
    }
    return Dialog(
      child: AspectRatio(
        aspectRatio:
            _initialized ? _videoPlayerController.value.aspectRatio : 16 / 9,
        child:
            _initialized && _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
