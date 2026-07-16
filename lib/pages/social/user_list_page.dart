import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../profile/user_profile_page.dart';

class UserListPage extends StatefulWidget {
  final int userId;
  final bool isFollowers;
  final String title;
  const UserListPage({super.key, required this.userId, required this.isFollowers, required this.title});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiClient();
      _users = widget.isFollowers
        ? await api.getFollowers(widget.userId)
        : await api.getFollowing(widget.userId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _users.isEmpty
          ? Center(child: Text('暂无${widget.title}', style: TextStyle(color: Colors.grey[400])))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                final uid = u['id'] is int ? u['id'] as int : int.tryParse('${u['id']}');
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text((u['nickname'] ?? '?')[0])),
                  title: Text(u['nickname'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(u['bio'] ?? ''),
                  onTap: () {
                    if (uid == null) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: uid)));
                  },
                );
              },
            ),
    );
  }
}
