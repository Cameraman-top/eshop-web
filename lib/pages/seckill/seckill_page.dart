import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class SeckillPage extends StatefulWidget {
  const SeckillPage({super.key});
  @override
  State<SeckillPage> createState() => _SeckillPageState();
}

class _SeckillPageState extends State<SeckillPage> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _events = await ApiClient().getSeckillEvents(); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('限时秒杀'), actions: [
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('刷新')),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        _events.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.flash_on_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16), Text('暂无秒杀活动', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
        ])) :
        ListView.builder(padding: const EdgeInsets.all(12), itemCount: _events.length, itemBuilder: (context, i) {
          final e = _events[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              Row(children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.flash_on, size: 40, color: Colors.red))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.flash_on, size: 16, color: Colors.red), const SizedBox(width: 4), Text('${e['sold_count'] ?? 0}人已抢', style: const TextStyle(fontSize: 12, color: Colors.red))]),
                  Text(e['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('¥${e['seckill_price']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                    const SizedBox(width: 8),
                    Text('¥${e['original_price']}', style: TextStyle(fontSize: 13, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                  value: (e['sold_count'] ?? 0) / (e['stock'] ?? 1), backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D4F)), minHeight: 8,
                ))),
                const SizedBox(width: 8),
                Text('剩余 ${(e['stock'] ?? 0) - (e['sold_count'] ?? 0)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => _buySeckill(e),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white),
                child: const Text('立即抢购'),
              )),
            ])),
          );
        }),
    );
  }

  Future<void> _buySeckill(Map<String, dynamic> e) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    try {
      await ApiClient().createOrder(user.token!, [{'product_id': e['product_id'] ?? 0, 'quantity': 1}]);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('抢购成功！')));
      _load();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('抢购失败: $err')));
    }
  }
}
