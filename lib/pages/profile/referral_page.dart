import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});
  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  List<Map<String, dynamic>> _earnings = [];
  double _total = 0;
  String? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    try {
      final res = await ApiClient().dio.get('/api/referral/earnings',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _earnings = List<Map<String, dynamic>>.from((res.data['data']['earnings'] as List).map((e) => Map<String, dynamic>.from(e)));
      _total = (res.data['data']['total'] as num).toDouble();
    } catch (_) {}
    try {
      final res2 = await ApiClient().dio.get('/api/referral',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _code = res2.data['data']['code'];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    if (!user.isLoggedIn) return Scaffold(appBar: AppBar(title: const Text('分销中心')), body: Center(child: Text('请先登录', style: TextStyle(color: Colors.grey[400]))));
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('分销中心')), body: const Center(child: CircularProgressIndicator()));

    final shareLink = _code != null ? 'http://localhost:9999?ref=${_code}' : '';

    return Scaffold(
      appBar: AppBar(title: const Text('分销中心')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Stats card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFF4D4F),
            child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Text('累计佣金', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('¥${_total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ])),
          ),
          const SizedBox(height: 16),
          // Share link
          if (_code != null) Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('我的分销链接', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Expanded(child: Text(shareLink, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { /* copy */ }),
                ]),
              ),
              const SizedBox(height: 8),
              Text('分享此链接，他人通过链接下单你获得 5% 佣金', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
          ),
          const SizedBox(height: 16),
          // Earnings list
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('佣金明细', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text('${_earnings.length} 笔', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ]),
          if (_earnings.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('暂无佣金记录', style: TextStyle(color: Colors.grey[400])))
          else
            ..._earnings.map((e) => Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: (e['status'] == 'settled' ? Colors.green : Colors.orange).withOpacity(0.1), child: Icon(Icons.monetization_on, color: e['status'] == 'settled' ? Colors.green : Colors.orange, size: 20)),
                title: Text('${e['buyer_name'] ?? '用户'} 下单', style: const TextStyle(fontSize: 14)),
                subtitle: Text(e['created_at'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                trailing: Text('+¥${(e['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.bold)),
              ),
            )),
        ]),
      ),
    );
  }
}
