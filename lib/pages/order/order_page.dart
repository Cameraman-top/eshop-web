import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import 'order_detail_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['全部', '待付款', '待发货', '待收货', '待评价'];
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      _orders = await ApiClient().getOrders(user.token!);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    if (!user.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的订单')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('请先登录查看订单', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ])),
      );
    }
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('我的订单')), body: const Center(child: CircularProgressIndicator()));

    final statusMap = {'pending': '待付款', 'paid': '待发货', 'shipped': '待收货', 'completed': '已完成', 'cancelled': '已取消'};

    return Scaffold(
      appBar: AppBar(title: const Text('我的订单'), bottom: TabBar(controller: _tabController, isScrollable: true, labelColor: const Color(0xFFFF4D4F), unselectedLabelColor: Colors.grey, tabs: _tabs.map((t) => Tab(text: t)).toList())),
      body: _orders.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无订单', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final o = _orders[index];
              final items = o['items'] as List? ?? [];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o['id']))).then((_) => _loadOrders()),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(o['order_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(statusMap[o['status']] ?? o['status'] ?? '', style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.w500)),
                      ]),
                      const Divider(),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Center(child: Text(item['product_image'] ?? '📦', style: const TextStyle(fontSize: 24)))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['product_name'] ?? '', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if ((item['spec'] ?? '').isNotEmpty) Text(item['spec'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ])),
                          Text('¥${(item['price'] as num).toStringAsFixed(0)} x${item['quantity']}', style: const TextStyle(fontSize: 14)),
                        ]),
                      )),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('共 ${items.length} 件商品', style: TextStyle(color: Colors.grey[500])),
                        Text('合计: ¥${(o['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                      ]),
                    ]),
                  ),
                ),
              );
            },
          ),
    );
  }
}
