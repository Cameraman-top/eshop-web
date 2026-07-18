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
  List<Map<String, dynamic>> _videos = [];
  final Map<int, bool> _likedSet = {};
  bool _loading = true;
  String? _error;
  int? _playingIdx;

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

  void _openPlayer(int idx) => setState(() => _playingIdx = idx);
  void _closePlayer() => setState(() => _playingIdx = null);

  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_playingIdx != null) return _buildPlayer();

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('短视频')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('短视频')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
      const SizedBox(height: 12),
      Text('加载失败', style: TextStyle(color: Colors.red[400])),
      TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, child: const Text('重试')),
    ])));
    if (_videos.isEmpty) return Scaffold(appBar: AppBar(title: const Text('短视频')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.videocam_off_outlined, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('暂无短视频', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () async { await Navigator.pushNamed(context, '/video/upload'); _load(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white), child: const Text('发布第一条')),
    ])));

    return Scaffold(
      appBar: AppBar(
        title: const Text('短视频'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () async { await Navigator.pushNamed(context, '/video/upload'); _load(); }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _videos.length,
          itemBuilder: (ctx, i) => _buildCard(i),
        ),
      ),
    );
  }

  Widget _buildCard(int i) {
    final v = _videos[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openPlayer(i),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Container(
            width: 100, height: 140,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white70)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(v['content'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              CircleAvatar(radius: 12, backgroundColor: Colors.grey[200], child: Text((v['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 10))),
              const SizedBox(width: 6),
              Text(v['nickname'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              Icon(Icons.favorite, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 2),
              Text('${v['like_count'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(width: 12),
              Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 2),
              Text('${v['comment_count'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
          ])),
        ])),
      ),
    );
  }

  Widget _buildPlayer() {
    final i = _playingIdx!;
    final v = _videos[i];
    final url = v['video_url'] ?? '';
    final pid = v['id'];
    final isLiked = _likedSet[pid] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (url.isNotEmpty) _VideoPlayer(viewTypeId: 'video-play-${v['id']}', url: url),
        SafeArea(child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _closePlayer),
          const SizedBox(width: 8),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('@${v['nickname'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
        ])),
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
              const SizedBox(height: 6),
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

class _VideoPlayer extends StatefulWidget {
  final String viewTypeId;
  final String url;
  const _VideoPlayer({required this.viewTypeId, required this.url});
  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  html.VideoElement? _video;

  @override
  void initState() {
    super.initState();
    _video = html.VideoElement()
      ..src = widget.url
      ..loop = true
      ..muted = false
      ..controls = false
      ..autoplay = true
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = 'black';
    ui_web.platformViewRegistry.registerViewFactory(widget.viewTypeId, (int viewId) => _video!);
  }

  @override
  void didUpdateWidget(_VideoPlayer old) {
    super.didUpdateWidget(old);
    if (widget.url != old.url && _video != null) { _video!.src = widget.url; _video!.play().catchError((_) {}); }
  }

  @override
  void dispose() { _video?.pause(); _video = null; super.dispose(); }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: widget.viewTypeId);
}
