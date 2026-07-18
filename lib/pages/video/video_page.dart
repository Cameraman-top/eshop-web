import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
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

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _current) setState(() => _current = page);
    });
  }

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

  @override
  void didUpdateWidget(VideoPage old) {
    super.didUpdateWidget(old);
    if (!widget.isActive && old.isActive) _hideAllVideos();
  }

  void _hideAllVideos() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) { (el as html.HtmlElement).style.display = 'none'; final v = el.querySelector('video'); if (v is html.VideoElement) v.pause(); }
  }

  void _showCurrentVideo() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) {
      final idx = (el as html.HtmlElement).dataset['videoPage'];
      if (idx == '$_current') { el.style.display = 'block'; final v = el.querySelector('video'); if (v is html.VideoElement) v.play().catchError((_) {}); }
      else { el.style.display = 'none'; final v = el.querySelector('video'); if (v is html.VideoElement) v.pause(); }
    }
  }

  @override
  void dispose() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) el.remove();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final els = html.document.querySelectorAll('[data-video-page]');
    for (final el in els) {
      final idx = (el as html.HtmlElement).dataset['videoPage'];
      if (idx != '$_current') continue;
      final v = el.querySelector('video');
      if (v is html.VideoElement) {
        if (v.paused) v.play().catchError((_) {});
        else v.pause();
        setState(() => _showPlayIcon = true);
        Future.delayed(const Duration(milliseconds: 500), () { if (mounted) setState(() => _showPlayIcon = false); });
      }
    }
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

    if (widget.isActive) WidgetsBinding.instance.addPostFrameCallback((_) => _showCurrentVideo());

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
    final pid = v['id'];
    final isLiked = _likedSet[pid] == true;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: () => _doubleTapLike(v),
      child: Stack(children: [
        _VideoInjector(videoId: 'video-$i', url: (i == _current && widget.isActive) ? url : '', pageIndex: i, isCurrent: i == _current && widget.isActive),
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
  void initState() { super.initState(); _createContainer(); }

  void _createContainer() {
    if (_created || widget.url.isEmpty) return;
    _created = true;
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
    _video = html.VideoElement()
      ..src = widget.url
      ..loop = true
      ..muted = true
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
    if (widget.isCurrent) _video!.play().catchError((_) {});
  }

  @override
  void didUpdateWidget(_VideoInjector old) {
    super.didUpdateWidget(old);
    if (widget.url.isEmpty && old.url.isNotEmpty) {
      _container?.remove();
      _container = null; _video = null; _created = false;
      return;
    }
    if (!_created && widget.url.isNotEmpty) _createContainer();
    if (widget.isCurrent != old.isCurrent && _container != null) {
      if (widget.isCurrent) { _container!.style.display = 'block'; _video?.play().catchError((_) {}); }
      else { _container!.style.display = 'none'; _video?.pause(); }
    }
    if (widget.url != old.url && _video != null) { _video!.src = widget.url; if (widget.isCurrent) _video!.play().catchError((_) {}); }
  }

  @override
  void dispose() { _container?.remove(); super.dispose(); }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
