import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'video_player_dialog.dart'; // see below

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Hardcoded media items; adjust paths as needed.
  final List<Map<String, String>> mediaItems = const [
    {'type': 'image', 'path': 'assets/jaiveer/jaiveer1.jpg'},
    {'type': 'image', 'path': 'assets/jaiveer/jaiveer2.jpg'},
    {'type': 'image', 'path': 'assets/jaiveer/jaiveer3.jpg'},
    {'type': 'image', 'path': 'assets/jaiveer/jaiveer4.jpg'},
    {'type': 'image', 'path': 'assets/jaiveer/jaiveer5.jpg'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid1.mp4'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid2.mp4'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid3.mp4'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid4.mp4'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid5.mp4'},
    {'type': 'video', 'path': 'assets/jaiveer/jaiveer-vid6.mp4'},
  ];

  List<Map<String, String>> get photoItems =>
      mediaItems.where((item) => item['type'] == 'image').toList();

  List<Map<String, String>> get videoItems =>
      mediaItems.where((item) => item['type'] == 'video').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photoItems.length,
      itemBuilder: (context, index) {
        final photo = photoItems[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (_) => Dialog(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: PhotoView(
                        imageProvider: AssetImage(photo['path']!),
                      ),
                    ),
                  ),
            );
          },
          child: Card(child: Image.asset(photo['path']!, fit: BoxFit.cover)),
        );
      },
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videoItems.length,
      itemBuilder: (context, index) {
        final video = videoItems[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => VideoPlayerDialog(videoPath: video['path']!),
            );
          },
          child: Card(
            child: Stack(
              children: [
                Container(
                  color: Colors.black12,
                  child: const Center(
                    child: Icon(
                      Icons.videocam,
                      size: 50,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.black45,
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
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
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Photos"), Tab(text: "Videos")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPhotoGrid(), _buildVideoGrid()],
      ),
    );
  }
}
