import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../profile/user_profile_page.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Map<String, dynamic>? _post;
  bool _loading = true;
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiClient().getPostDetail(widget.postId);
      _post = p;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _toggleLike() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    if (_post == null) return;
    final isLiked = _post!['is_liked'] == true;
    setState(() {
      _post!['is_liked'] = !isLiked;
      _post!['like_count'] = (_post!['like_count'] ?? 0) + (isLiked ? -1 : 1);
    });
    try {
      await ApiClient().toggleLike(widget.postId, user.token!, !isLiked);
    } catch (_) {
      if (mounted) {
        setState(() {
          _post!['is_liked'] = isLiked;
          _post!['like_count'] = (_post!['like_count'] ?? 0) + (isLiked ? 1 : -1);
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    final c = _commentCtrl.text.trim();
    if (c.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient().addComment(widget.postId, user.token!, c);
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('评论失败: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _post;
    if (p == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('帖子不存在或已删除')));
    final comments = (p['comments'] as List?) ?? [];
    final isLiked = p['is_liked'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('帖子详情')),
      body: Column(children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comments.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) return _buildPost(p, isLiked);
            final cm = comments[i - 1] as Map<String, dynamic>;
            return _buildComment(cm);
          },
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(hintText: '写评论...', isDense: true, border: OutlineInputBorder()),
              onSubmitted: (_) => _sendComment(),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _sendComment,
              icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Color(0xFFFF4D4F)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPost(Map<String, dynamic> p, bool isLiked) {
    final uid = p['user_id'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () {
          if (uid != null) Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: uid is int ? uid : int.parse('$uid'))));
        },
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: Colors.grey[200], child: Text((p['nickname'] ?? '?')[0])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['nickname'] ?? '匿名', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(p['created_at'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ]),
        ]),
      ),
      if ((p['title'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 12), Text(p['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
      const SizedBox(height: 10),
      Text(p['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6)),
      const SizedBox(height: 14),
      Row(children: [
        GestureDetector(onTap: _toggleLike, child: Row(children: [
          Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: isLiked ? const Color(0xFFFF4D4F) : Colors.grey[500]),
          const SizedBox(width: 4),
          Text('${p['like_count'] ?? 0}', style: TextStyle(color: Colors.grey[600])),
        ])),
        const SizedBox(width: 24),
        Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text('${p['comment_count'] ?? 0}', style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text('浏览 ${p['view_count'] ?? 0}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ]),
      const Divider(height: 32),
      Text('评论 ${comments0(p)}', style: const TextStyle(fontWeight: FontWeight.w600)),
    ]);
  }

  int comments0(Map<String, dynamic> p) => (p['comment_count'] ?? ((p['comments'] as List?)?.length ?? 0)) as int;

  Widget _buildComment(Map<String, dynamic> cm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: Colors.grey[200], child: Text((cm['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cm['nickname'] ?? '匿名', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(cm['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 2),
          Text(cm['created_at'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ])),
      ]),
    );
  }
}
