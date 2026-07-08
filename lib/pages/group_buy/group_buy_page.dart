import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class GroupBuyPage extends StatefulWidget {
  const GroupBuyPage({super.key});
  @override
  State<GroupBuyPage> createState() => _GroupBuyPageState();
}

class _GroupBuyPageState extends State<GroupBuyPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _groups = await ApiClient().getGroupBuys();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拼团'), actions: [
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('刷新')),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        _groups.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无拼团', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
        ])) :
        ListView.builder(padding: const EdgeInsets.all(12), itemCount: _groups.length, itemBuilder: (context, i) {
          final g = _groups[i];
          final remaining = (g['required_count'] ?? 2) - (g['current_count'] ?? 1);
          final progress = (g['current_count'] ?? 1) / (g['required_count'] ?? 2);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Center(child: Text(g['image'] ?? '📦', style: const TextStyle(fontSize: 32)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('拼团价 ¥${g['group_price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                    const SizedBox(width: 8),
                    Text('¥${g['original_price']}', style: TextStyle(fontSize: 13, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 12),
              Text('还差 $remaining 人成团', style: TextStyle(fontSize: 13, color: Colors.orange[700])),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D4F)), minHeight: 6))),
                const SizedBox(width: 8),
                Text('${g['current_count']}/${g['required_count']}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => _joinGroup(g),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('立即参团', style: TextStyle(fontSize: 15)),
              )),
            ])),
          );
        }),
    );
  }

  Future<void> _joinGroup(Map<String, dynamic> g) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    try {
      await ApiClient().joinGroupBuy(g['id'], user.token!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('参团成功！')));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('参团失败: $e')));
    }
  }
}
