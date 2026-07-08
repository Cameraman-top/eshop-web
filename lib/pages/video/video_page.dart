import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html;
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class VideoPage extends StatefulWidget {
  final bool isActive;
  const VideoPage({super.key, this.isActive = true});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final _controller = PageController();
  List<Map<String, dynamic>> _videos = [];
  int _current = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _current) {
        setState(() => _current = page);
      }
    });
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/api/videos');
      _videos = List<Map<String, dynamic>>.from((res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void didUpdateWidget(VideoPage old) {
    super.didUpdateWidget(old);
    if (!widget.isActive && old.isActive) {
      _hideAllVideos();
    } else if (widget.isActive && !old.isActive) {
      setState(() {});
    }
  }

  void _hideAllVideos() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) {
      (el as html.HtmlElement).style.display = 'none';
      final video = el.querySelector('video');
      if (video is html.VideoElement) video.pause();
    }
  }

  void _showCurrentVideo() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) {
      final pageIdx = (el as html.HtmlElement).dataset['videoPage'];
      if (pageIdx == '$_current') {
        el.style.display = 'block';
        final v = el.querySelector('video');
        if (v is html.VideoElement) v.play();
      } else {
        el.style.display = 'none';
        final v = el.querySelector('video');
        if (v is html.VideoElement) v.pause();
      }
    }
  }

  @override
  void dispose() {
    // Remove all video containers
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) {
      el.remove();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
      const SizedBox(height: 12),
      Text('加载失败', style: TextStyle(color: Colors.red[400], fontSize: 16)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 12), textAlign: TextAlign.center)),
      TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, child: const Text('重试')),
    ])));
    if (_videos.isEmpty) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.videocam_off_outlined, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('暂无短视频', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
    ])));

    // Show current video when page is active
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCurrentVideo());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (ctx, i) => _buildPage(i),
        ),
        SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          const Text('短视频', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () async { await Navigator.pushNamed(context, '/video/upload'); _load(); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, color: Colors.white, size: 16), SizedBox(width: 4), Text('发布', style: TextStyle(color: Colors.white, fontSize: 13))])),
          ),
        ]))),
        SafeArea(child: Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: List.generate(_videos.length, (i) => Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 1), color: i == _current ? Colors.white : Colors.white24)))))),
      ]),
    );
  }

  Widget _buildPage(int i) {
    final v = _videos[i];
    final url = v['video_url'] ?? '';

    return Stack(children: [
      // Video placeholder - actual video is injected via _VideoInjector
      _VideoInjector(videoId: 'video-$i', url: url, pageIndex: i, isCurrent: i == _current && widget.isActive),
      Positioned(bottom: 0, left: 0, right: 0, child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(v['content'] ?? '', style: TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Text((v['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 10, color: Colors.white))),
              const SizedBox(width: 6),
              Text(v['nickname'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ]),
          ])),
          Column(children: [
            _actionBtn(Icons.favorite, '${v['like_count'] ?? 0}', () {}),
            const SizedBox(height: 16),
            _actionBtn(Icons.chat_bubble_outline, '${v['comment_count'] ?? 0}', () {}),
            const SizedBox(height: 16),
            _actionBtn(Icons.share, '分享', () {}),
          ]),
        ]),
      )),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

// Creates video container in body, controls via display:none/block
class _VideoInjector extends StatefulWidget {
  final String videoId;
  final String url;
  final int pageIndex;
  final bool isCurrent;
  const _VideoInjector({required this.videoId, required this.url, required this.pageIndex, required this.isCurrent});
  @override
  State<_VideoInjector> createState() => _VideoInjectorState();
}

class _VideoInjectorState extends State<_VideoInjector> {
  html.DivElement? _container;
  html.VideoElement? _video;
  bool _created = false;

  @override
  void initState() {
    super.initState();
    _createContainer();
  }

  void _createContainer() {
    if (_created || widget.url.isEmpty) return;
    _created = true;

    // Create container
    _container = html.DivElement()
      ..dataset['videoPage'] = '${widget.pageIndex}'
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.zIndex = '9999'
      ..style.pointerEvents = 'none'
      ..style.backgroundColor = 'black'
      ..style.display = widget.isCurrent ? 'block' : 'none';

    // Create video
    _video = html.VideoElement()
      ..src = widget.url
      ..loop = true
      ..muted = false
      ..controls = false
      ..autoplay = widget.isCurrent
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    _container!.append(_video!);
    html.document.body?.append(_container!);

    if (widget.isCurrent) {
      _video!.play().catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(_VideoInjector old) {
    super.didUpdateWidget(old);
    if (!_created && widget.url.isNotEmpty) {
      _createContainer();
    }
    if (widget.isCurrent != old.isCurrent && _container != null) {
      if (widget.isCurrent) {
        _container!.style.display = 'block';
        _video?.play().catchError((_) {});
      } else {
        _container!.style.display = 'none';
        _video?.pause();
      }
    }
    if (widget.url != old.url && _video != null) {
      _video!.src = widget.url;
      if (widget.isCurrent) _video!.play().catchError((_) {});
    }
  }

  @override
  void dispose() {
    _container?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
