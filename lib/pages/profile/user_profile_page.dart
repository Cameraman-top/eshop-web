import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../social/user_list_page.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  const UserProfilePage({super.key, required this.userId});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    try {
      final res = await ApiClient().dio.get('/api/user/profile', queryParameters: {'user_id': widget.userId},
        options: user.isLoggedIn ? Options(headers: {'Authorization': 'Bearer ${user.token}'}) : null,
      );
      if (mounted) setState(() { _data = res.data['data']; _isFollowing = _data?['is_following'] == true; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _toggleFollow() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    try {
      await ApiClient().follow(widget.userId, user.token!, unfollow: _isFollowing);
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('达人主页')), body: const Center(child: CircularProgressIndicator()));
    if (_data == null) return Scaffold(appBar: AppBar(title: const Text('达人主页')), body: Center(child: Text('用户不存在', style: TextStyle(color: Colors.grey[400]))));

    final u = _data!['user'];
    final posts = _data!['posts'] as List;
    final followers = _data!['followers'];
    final following = _data!['following'];

    return Scaffold(
      appBar: AppBar(title: Text(u['nickname'] ?? '用户主页')),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFFF4D4F).withOpacity(0.8), const Color(0xFFFF7A45).withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(children: [
              CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Text((u['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 32, color: Colors.white))),
              const SizedBox(height: 12),
              Text(u['nickname'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              if ((u['bio'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(u['bio'] ?? '', style: TextStyle(color: Colors.white70, fontSize: 14))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _stat('${followers}', '粉丝', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserListPage(userId: widget.userId, isFollowers: true, title: '粉丝')))),
                const SizedBox(width: 40),
                _stat('${following}', '关注', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserListPage(userId: widget.userId, isFollowers: false, title: '关注')))),
                const SizedBox(width: 40),
                _stat('${posts.length}', '笔记', onTap: null),
              ]),
              const SizedBox(height: 16),
              // Follow button
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.white24 : Colors.white,
                  foregroundColor: _isFollowing ? Colors.white : const Color(0xFFFF4D4F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(_isFollowing ? '已关注' : '+ 关注', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          // Posts grid
          if (posts.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.post_add, size: 48, color: Colors.grey[300]), const SizedBox(height: 8), Text('暂无笔记', style: TextStyle(color: Colors.grey[400]))]))
          else
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: posts.length,
              itemBuilder: (ctx, i) {
                final p = posts[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Container(color: Colors.grey[100], child: Center(child: Text(p['images']?.isNotEmpty == true ? p['images'][0] : '📝', style: const TextStyle(fontSize: 40))))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(p['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: Row(children: [
                      Icon(Icons.favorite_border, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('${p['like_count'] ?? 0}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ])),
                  ]),
                );
              },
            ),
        ]),
      ),
    );
  }

  Widget _stat(String value, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}
