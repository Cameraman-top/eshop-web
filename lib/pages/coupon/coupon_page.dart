import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});
  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allCoupons = [];
  List<Map<String, dynamic>> _myCoupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      _allCoupons = await ApiClient().getCoupons();
      final user = context.read<UserProvider>();
      if (user.isLoggedIn) {
        _myCoupons = await ApiClient().getMyCoupons(user.token!);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('优惠券'), bottom: TabBar(
        controller: _tabController, labelColor: const Color(0xFFFF4D4F), unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: '领券中心'), Tab(text: '我的优惠券')],
      )),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        TabBarView(controller: _tabController, children: [
          _buildCouponList(_allCoupons, showClaim: true),
          _buildCouponList(_myCoupons, showClaim: false),
        ]),
    );
  }

  Widget _buildCouponList(List<Map<String, dynamic>> coupons, {bool showClaim = false}) {
    if (coupons.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 12), Text(showClaim ? '暂无可领优惠券' : '暂无优惠券', style: TextStyle(color: Colors.grey[400])),
    ]));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: coupons.length, itemBuilder: (context, i) {
      final c = coupons[i];
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(child: Row(children: [
          Container(width: 100, decoration: const BoxDecoration(color: Color(0xFFFF4D4F), borderRadius: BorderRadius.horizontal(left: Radius.circular(12))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('¥', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('${c['discount'] ?? c['amount'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ]),
              Text(c['type'] == 'discount' ? '折' : '元', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text('满 ¥${c['min_amount'] ?? 0} 可用', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('有效期: ${c['expire_at'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]))),
          if (showClaim) Padding(padding: const EdgeInsets.only(right: 12), child: ElevatedButton(
            onPressed: () => _claim(c),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('领取'),
          )),
        ])),
      );
    });
  }

  Future<void> _claim(Map<String, dynamic> c) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    try {
      await ApiClient().claimCoupon(user.token!, c['id']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('领取成功！')));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('领取失败: $e')));
    }
  }
}
