import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiClient().dio.get('/api/notifications',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _items = List<Map<String, dynamic>>.from((res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markRead(int? id) async {
    final user = context.read<UserProvider>();
    try {
      final params = <String, dynamic>{};
      if (id != null) params['id'] = id;
      await ApiClient().dio.get('/api/notification/read',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _load();
    } catch (_) {}
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'order': return Icons.receipt_long;
      case 'group': return Icons.group;
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble_outline;
      case 'follow': return Icons.person_add;
      default: return Icons.notifications_outlined;
    }
  }

  Color _color(String? type) {
    switch (type) {
      case 'order': return const Color(0xFFFF4D4F);
      case 'group': return Colors.orange;
      case 'like': return Colors.pink;
      case 'comment': return Colors.blue;
      case 'follow': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    if (!user.isLoggedIn) {
      return Scaffold(appBar: AppBar(title: const Text('消息通知')), body: Center(child: Text('请先登录', style: TextStyle(color: Colors.grey[400]))));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [TextButton(onPressed: () => _markRead(null), child: const Text('全部已读'))],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('暂无通知', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            ]))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final isRead = item['is_read'] == 1;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: _color(item['type']).withOpacity(0.1), child: Icon(_icon(item['type']), color: _color(item['type']), size: 20)),
                  title: Text(item['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 15)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((item['content'] ?? '').isNotEmpty) Text(item['content'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500]), maxLines: 2),
                    Text(item['created_at'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ]),
                  trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF4D4F), shape: BoxShape.circle)) : null,
                  onTap: () => _markRead(item['id']),
                );
              },
            ),
    );
  }
}
