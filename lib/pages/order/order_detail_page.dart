import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import 'package:dio/dio.dart';
import 'pay_page.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    try {
      final res = await ApiClient().dio.post('/api/order/detail',
        data: {'order_id': widget.orderId},
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      final data = res.data['data'];
      setState(() {
        _order = Map<String, dynamic>.from(data['order']);
        _items = (data['items'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _action(String act) async {
    final user = context.read<UserProvider>();
    try {
      await ApiClient().dio.post('/api/order/$act',
        data: {'order_id': widget.orderId},
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  String _statusText(String? s) {
    switch (s) {
      case 'pending': return '待付款';
      case 'paid': return '待发货';
      case 'shipped': return '待收货';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('订单详情')), body: const Center(child: CircularProgressIndicator()));
    if (_order == null) return Scaffold(appBar: AppBar(title: const Text('订单详情')), body: const Center(child: Text('订单不存在')));

    final status = _order!['status'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('订单: ${_order!['order_no'] ?? ''}')),
      body: Column(children: [
        // Status
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          color: const Color(0xFFFF4D4F).withOpacity(0.05),
          child: Row(children: [
            Icon(status == 'completed' ? Icons.check_circle : status == 'cancelled' ? Icons.cancel : Icons.local_shipping, color: const Color(0xFFFF4D4F), size: 28),
            const SizedBox(width: 12),
            Text(_statusText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ]),
        ),
        // Items
        Expanded(child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (ctx, i) {
            final item = _items[i];
            return ListTile(
              leading: Text(item['product_image'] ?? '', style: const TextStyle(fontSize: 32)),
              title: Text(item['product_name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${item['spec'] ?? ''} x${item['quantity']}', style: TextStyle(color: Colors.grey[500])),
              trailing: Text('¥${item['price']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            );
          },
        )),
        // Total + Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('合计', style: TextStyle(fontSize: 16)),
              Text('¥${_order!['total']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
            ]),
            const SizedBox(height: 12),
            if (status == 'pending')
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _action('cancel'), child: const Text('取消订单'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayPage(orderId: widget.orderId, total: (_order!['total'] as num).toDouble()))).then((paid) { if (paid == true) _load(); }),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F)),
                  child: const Text('去支付', style: TextStyle(color: Colors.white)),
                )),
              ]),
            if (status == 'paid')
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _action('cancel'), child: const Text('取消订单'))),
            if (status == 'shipped')
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _action('confirm'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F)), child: const Text('确认收货', style: TextStyle(color: Colors.white)))),
          ]),
        ),
      ]),
    );
  }
}
