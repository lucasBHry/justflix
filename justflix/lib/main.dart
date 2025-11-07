import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

// Si estás en Web usa localhost, si no Android usa 10.0.2.2
final String apiBase = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustFlix',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomePage(),
    );
  }
}

class Video {
  final String id;
  final String topic;
  final String description;
  final double duration;
  final String thumbnail;

  Video({
    required this.id,
    required this.topic,
    required this.description,
    required this.duration,
    required this.thumbnail,
  });

  factory Video.fromJson(Map<String, dynamic> j) {
    num d = j['duration'] ?? 0;
    if (d is int) d = d.toDouble();
    return Video(
      id: j['id'] ?? '',
      topic: j['topic'] ?? '',
      description: j['description'] ?? '',
      duration: d.toDouble(),
      thumbnail: j['thumbnail'] ?? '',
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Video> videos = [];
  Video? selectedVideo;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  void loadVideos() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await fetchVideoList();
      setState(() {
        videos = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<List<Video>> fetchVideoList() async {
    final uri = Uri.parse('$apiBase/api/videolist');
    final res = await http.get(uri);

    if (res.statusCode != 200) throw Exception('Error: ${res.statusCode}');
    final data = json.decode(res.body) as List;
    return data.map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> fetchVideoById(String id) async {
    final uri = Uri.parse('$apiBase/api/videolist/id/$id');
    final res = await http.get(uri);

    if (res.statusCode != 200) throw Exception('Error: ${res.statusCode}');
    final data = json.decode(res.body);
    return Video.fromJson(data);
  }

  void tapVideo(Video v) async {
    setState(() {
      selectedVideo = v;
    });
    try {
      final full = await fetchVideoById(v.id);
      setState(() {
        selectedVideo = full;
      });
    } catch (e) {}
  }

  Widget makeList() {
    if (loading) return Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (videos.isEmpty) return Center(child: Text('No hay videos'));
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (c, i) {
        final v = videos[i];
        return ListTile(
          title: Text(v.description),
          subtitle: Text('${v.topic}  ${v.duration}s'),
          leading: Icon(Icons.video_library),
          onTap: () => tapVideo(v),
        );
      },
    );
  }

  Widget makeDetail() {
    if (selectedVideo == null) {
      return Center(child: Text('Selecciona un video'));
    }
    final v = selectedVideo!;
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v.description,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Tema: ${v.topic}'),
          SizedBox(height: 8),
          Text('Duración: ${v.duration}s'),
          SizedBox(height: 8),
          Icon(Icons.image, size: 80, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('JustFlix')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool narrow = constraints.maxWidth < 600;
          if (narrow) {
            return Column(
              children: [
                Expanded(child: makeList()),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: makeDetail(),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Container(
                    width: constraints.maxWidth * 0.4, child: makeList()),
                VerticalDivider(width: 1),
                Expanded(child: makeDetail()),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadVideos,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
