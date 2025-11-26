import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(MyApp()); // inicia la app
}

// url base segun plataforma
final String apiBase = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

// widget principal
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustFlix',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomePage(), // llama a la pagina home
    );
  }
}

// modelo de video
class Video {
  final String id;
  final String topic;
  final String description;
  final double duration;
  final String thumbnail;
  final String stream;

  Video({required this.id, required this.topic, required this.description, required this.duration, required this.thumbnail, required this.stream});

  factory Video.fromJson(Map<String, dynamic> j) {
    num d = j['duration'] ?? 0;
    if (d is int) d = d.toDouble();
    return Video(
      id: j['id'] ?? '',
      topic: j['topic'] ?? '',
      description: j['description'] ?? '',
      duration: d.toDouble(),
      thumbnail: j['thumbnail'] ?? '',
      stream: j['stream'] ?? '',
    );
  }
}

// pagina principal con estado
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Video> videos = []; // lista de videos
  Video? selectedVideo; // video seleccionado
  bool loading = true; 
  String? error;

  @override
  void initState() {
    super.initState();
    loadVideos(); // carga videos al iniciar
  }

  void loadVideos() async { // carga lista de videos
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

  Future<List<Video>> fetchVideoList() async { // obtiene lista de api
    final uri = Uri.parse('$apiBase/api/videolist');
    final res = await http.get(uri);

    if (res.statusCode != 200) throw Exception('Error: ${res.statusCode}');
    final data = json.decode(res.body) as List;
    return data.map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> fetchVideoById(String id) async { // obtiene video por id
    final uri = Uri.parse('$apiBase/api/videolist/id/$id');
    final res = await http.get(uri);

    if (res.statusCode != 200) throw Exception('Error: ${res.statusCode}');
    final data = json.decode(res.body);
    return Video.fromJson(data);
  }

  void tapVideo(Video v) async { // selecciona un video
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

  Widget makeList() { // lista de videos
    if (loading) return Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (videos.isEmpty) return Center(child: Text('No hay videos'));
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (c, i) {
        final v = videos[i];
        return ListTile(
          title: Text(v.description),
          onTap: () => tapVideo(v),
        );
      },
    );
  }

  Widget makeDetail() { // detalle del video seleccionado
    if (selectedVideo == null) return Center(child: Text('Selecciona un video'));

    final v = selectedVideo!;

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v.description, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Expanded(child: VideoWidget(url: '$apiBase${v.stream}')), // reproductor de video
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // construye la UI
    return Scaffold(
      appBar: AppBar(title: Text('JustFlix')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool narrow = constraints.maxWidth < 600;
          if (narrow) { // vista movil
            return Column(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                  child: makeDetail(),
                ),
                Expanded(child: makeList()),
              ],
            );
          } else { // vista horizontal
            return Row(
              children: [
                Container(width: constraints.maxWidth * 0.4, child: makeList()),
                VerticalDivider(width: 1),
                Expanded(child: makeDetail()),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadVideos,
        child: Icon(Icons.refresh), // boton recargar
      ),
    );
  }
}

// widget de video
class VideoWidget extends StatefulWidget {
  final String url;
  const VideoWidget({required this.url});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _createController(widget.url); // crea controlador
  }

  void _createController(String url) { // inicializa video
    initialized = false;

    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _controller = VideoPlayerController.network(url);
    }

    _controller.initialize().then((_) {
      setState(() => initialized = true);
      _controller.play();
    });
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) { // actualiza video
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.pause();
      _controller.dispose();
      _createController(widget.url);
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // limpia controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Positioned.fill(
          child: VideoPlayerControlsAdvanced(controller: _controller), // controles video
        ),
      ],
    );
  }
}

// controles del video
class VideoPlayerControlsAdvanced extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPlayerControlsAdvanced({required this.controller});

  @override
  State<VideoPlayerControlsAdvanced> createState() => _VideoPlayerControlsAdvancedState();
}

class _VideoPlayerControlsAdvancedState extends State<VideoPlayerControlsAdvanced> {
  bool showControls = false;
  Timer? hideTimer;

  void toggleControls() { // muestra/oculta controles
    setState(() => showControls = !showControls);
    _restartHideTimer();
  }

  void _restartHideTimer() { // temporizador ocultar controles
    hideTimer?.cancel();
    if (showControls) {
      hideTimer = Timer(Duration(seconds: 3), () {
        setState(() => showControls = false);
      });
    }
  }

  void enterFullscreen() { // pantalla completa
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: widget.controller.value.aspectRatio,
                    child: VideoPlayer(widget.controller),
                  ),
                ),
                Positioned.fill(
                  child: Stack(
                    children: [
                      VideoPlayerControlsAdvanced(controller: widget.controller),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: Icon(Icons.fullscreen_exit, color: Colors.white, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatDuration(Duration d) { // formatea tiempo
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) { // construye controles
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return GestureDetector(
      onTap: toggleControls,
      child: AnimatedOpacity(
        opacity: showControls ? 1 : 0,
        duration: Duration(milliseconds: 200),
        child: Container(
          color: Colors.black38,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded( // play/pause
                child: Center(
                  child: IconButton(
                    iconSize: 64,
                    color: Colors.white,
                    icon: Icon(widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                      });
                      _restartHideTimer();
                    },
                  ),
                ),
              ),
              Row( // barra progreso y tiempos
                children: [
                  Text(formatDuration(position), style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: position.inSeconds.toDouble(),
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      activeColor: Colors.red,
                      onChanged: (v) {
                        widget.controller.seekTo(Duration(seconds: v.toInt()));
                        _restartHideTimer();
                      },
                    ),
                  ),
                  Text(formatDuration(duration), style: TextStyle(color: Colors.white)),
                ],
              ),
              Row( // boton fullscreen
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 28,
                    color: Colors.white,
                    icon: Icon(Icons.fullscreen),
                    onPressed: enterFullscreen,
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
