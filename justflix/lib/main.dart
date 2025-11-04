import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Lista de Vídeos'),
    );
  }
}

class Video {
  final String topic;
  final String description;
  final double duration;

  Video(this.topic, this.description, this.duration);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Video> videos = [
    Video('Flutter', 'Introducción a Flutter', 120),
    Video('Dart', 'Fundamentos de Dart', 90),
    Video('NodeJS', 'Backend con NodeJS', 150),
  ];

  Video? selectedVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
        ? Column(
            children: [
              Expanded(child: _buildVideoList()),
              if (selectedVideo != null) _buildVideoDetail(selectedVideo!),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildVideoList()),
              if (selectedVideo != null) Expanded(child: _buildVideoDetail(selectedVideo!)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return ListTile(
          leading: const Text('[Aquí va una foto]'),
          title: Text(video.topic),
          subtitle: Text('${video.duration.toInt()} seg'),
          onTap: () {
            setState(() {
              selectedVideo = video;
            });
          },
        );
      },
    );
  }

  Widget _buildVideoDetail(Video video) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(video.topic, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(video.description),
            const SizedBox(height: 8),
            Text('Duración: ${video.duration.toInt()} seg'),
            const SizedBox(height: 8),
            const Text('[Aquí va una foto]'),
          ],
        ),
      ),
    );
  }
}
