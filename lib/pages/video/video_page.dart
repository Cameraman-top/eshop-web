import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../profile/user_profile_page.dart';
import '../social/post_detail_page.dart';

class VideoPage extends StatefulWidget {
  final bool isActive;
  const VideoPage({super.key, this.isActive = true});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final _controller = PageController();
  List<Map<String, dynamic>> _videos = [];
  final Map<int, bool> _likedSet = {};
  int _current = 0;
  bool _loading = true;
  String? _error;
  bool _showPlayIcon = false;
  bool _showHeart = false;
  bool _playing = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/api/videos');
      _videos = List<Map<String, dynamic>>.from((res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      for (final v in _videos) {
        final pid = v['id'] as int?;
        if (pid != null && v['is_liked'] == true) _likedSet[pid] = true;
      }
    } catch (e) { _error = '$e'; }
    if (mounted) setState(() => _loading = false);
  }

  void _togglePlayPause() {
    setState(() { _playing = !_playing; _showPlayIcon = true; });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) setState(() => _showPlayIcon = false); });
  }

  Future<void> _doubleTapLike(Map<String, dynamic> v) async {
    final pid = v['id'] as int?;
    if (pid == null) return;
    if (_likedSet[pid] == true) {
      setState(() => _showHeart = true);
      Future.delayed(const Duration(milliseconds: 600), () { if (mounted) setState(() => _showHeart = false); });
      return;
    }
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    setState(() { _likedSet[pid] = true; v['like_count'] = (v['like_count'] ?? 0) + 1; _showHeart = true; });
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) setState(() => _showHeart = false); });
    try {
      await ApiClient().toggleLike(pid, user.token!, true);
    } catch (_) { if (mounted) setState(() { _likedSet[pid] = false; v['like_count'] = (v['like_count'] ?? 1) - 1; }); }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
      const SizedBox(height: 12),
      Text('加载失败', style: TextStyle(color: Colors.red[400], fontSize: 16)),
      TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, child: const Text('重试')),
    ])));
    if (_videos.isEmpty) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.videocam_off_outlined, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('暂无短视频', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () async { await Navigator.pushNamed(context, '/video/upload'); _load(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white), child: const Text('发布第一条')),
    ])));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          onPageChanged: (i) => setState(() { _current = i; _playing = true; }),
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
    final pid = v['id'];
    final isLiked = _likedSet[pid] == true;
    final active = i == _current && widget.isActive;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: () => _doubleTapLike(v),
      child: Stack(children: [
        if (url.isNotEmpty) _VideoInjector(viewTypeId: 'video-${v['id']}', url: url, isCurrent: active, playing: active && _playing),
        if (_showPlayIcon && i == _current)
          const Center(child: Icon(Icons.play_arrow, color: Colors.white70, size: 80)),
        if (_showHeart && i == _current)
          Center(child: IgnorePointer(child: AnimatedScale(scale: _showHeart ? 1.3 : 1.0, duration: const Duration(milliseconds: 300), curve: Curves.elasticOut, child: const Icon(Icons.favorite, color: Colors.redAccent, size: 100)))),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () {
                  final uid = v['user_id'];
                  if (uid != null) Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: uid is int ? uid : int.parse('$uid'))));
                },
                child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Text((v['nickname'] ?? '?')[0], style: const TextStyle(color: Colors.white))),
                  const SizedBox(width: 8),
                  Text(v['nickname'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
              if ((v['title'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), Text(v['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))],
              const SizedBox(height: 4),
              Text(v['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 12),
            Column(children: [
              _actionBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.redAccent : Colors.white, '${v['like_count'] ?? 0}', () => _toggleLike(v)),
              const SizedBox(height: 18),
              _actionBtn(Icons.chat_bubble_outline, Colors.white, '${v['comment_count'] ?? 0}', () {
                if (pid is int) Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: pid)));
              }),
              const SizedBox(height: 18),
              _actionBtn(Icons.share, Colors.white, '分享', () {}),
            ]),
          ]),
        )),
      ]),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> v) async {
    final pid = v['id'] as int?;
    if (pid == null) return;
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    final wasLiked = _likedSet[pid] == true;
    setState(() { _likedSet[pid] = !wasLiked; v['like_count'] = (v['like_count'] ?? 0) + (wasLiked ? -1 : 1); });
    try { await ApiClient().toggleLike(pid, user.token!, !wasLiked); } catch (_) { if (mounted) setState(() { _likedSet[pid] = wasLiked; v['like_count'] = (v['like_count'] ?? 0) + (wasLiked ? 1 : -1); }); }
  }

  Widget _actionBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class _VideoInjector extends StatefulWidget {
  final String viewTypeId;
  final String url;
  final bool isCurrent;
  final bool playing;
  const _VideoInjector({required this.viewTypeId, required this.url, required this.isCurrent, this.playing = true});
  @override
  State<_VideoInjector> createState() => _VideoInjectorState();
}

class _VideoInjectorState extends State<_VideoInjector> {
  html.VideoElement? _video;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _video = html.VideoElement()
      ..src = widget.url
      ..loop = true
      ..muted = true
      ..controls = false
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = 'black';
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(widget.viewTypeId, (int viewId) {
      return _video!;
    });
    if (!widget.isCurrent || !widget.playing) _video!.pause();
  }

  @override
  void didUpdateWidget(_VideoInjector old) {
    super.didUpdateWidget(old);
    if (_video == null) return;
    if (widget.url != old.url) { _video!.src = widget.url; }
    if (widget.playing != old.playing || widget.isCurrent != old.isCurrent) {
      final shouldPlay = widget.isCurrent && widget.playing;
      if (shouldPlay) _video!.play().catchError((_) {});
      else _video!.pause();
    }
  }

  @override
  void dispose() { _video?.pause(); _video = null; super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_registered) return Container(color: Colors.black);
    return HtmlElementView(viewType: widget.viewTypeId);
  }
}
