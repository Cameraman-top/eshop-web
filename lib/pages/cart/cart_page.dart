import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../order/pay_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _serverItems = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      setState(() { _loading = false; });
      return;
    }
    setState(() { _loading = true; _err = null; });
    try {
      final items = await ApiClient().getCart(user.userId!);
      if (mounted) setState(() { _serverItems = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = '加载失败: $e'; _loading = false; });
    }
  }

  Future<void> _changeQty(Map<String, dynamic> item, int newQty) async {
    final user = context.read<UserProvider>();
    if (newQty <= 0) {
      await _remove(item);
      return;
    }
    final cid = item['id'];
    setState(() => item['quantity'] = newQty);  // optimistic
    try {
      await ApiClient().updateCartItem(cid, newQty);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新失败，重试中...')));
      _load();
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final user = context.read<UserProvider>();
    final cid = item['id'];
    setState(() => _serverItems.removeWhere((x) => x['id'] == cid));  // optimistic
    try {
      await ApiClient().removeCartItem(cid);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
      _load();
    }
  }

  Future<void> _clear() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      context.read<CartProvider>().clear();
      return;
    }
    setState(() => _serverItems = []);
    try {
      await ApiClient().dio.post('/api/cart',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
        data: {'action': 'clear'});
    } catch (_) {
      _load();
    }
  }

  double get _total => _serverItems.fold(0.0, (s, i) => s + ((i['price'] as num?)?.toDouble() ?? 0) * (i['quantity'] as int? ?? 0));
  int get _count => _serverItems.fold(0, (s, i) => s + (i['quantity'] as int? ?? 0));

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>();
    final isLoggedIn = user.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          if ((isLoggedIn && _serverItems.isNotEmpty) || (!isLoggedIn && context.watch<CartProvider>().itemCount > 0))
            TextButton(onPressed: _clear, child: const Text('清空', style: TextStyle(color: Colors.red))),
        ],
      ),
      body: !isLoggedIn
        ? _buildLocalCartFallback()
        : _loading
          ? const Center(child: CircularProgressIndicator())
          : (_err != null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_err!, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('重试'))]))
            : _serverItems.isEmpty
              ? _buildEmpty()
              : _buildServerList()),
      bottomNavigationBar: isLoggedIn && !_loading && _serverItems.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('购物车是空的', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/category'), child: const Text('去逛逛')),
        ],
      ),
    );
  }

  Widget _buildServerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _serverItems.length,
      itemBuilder: (context, index) {
        final item = _serverItems[index];
        final name = item['name'] as String? ?? '';
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final image = item['image'] as String? ?? '';
        final spec = item['spec'] as String? ?? '';
        final qty = item['quantity'] as int? ?? 1;
        return Dismissible(
          key: Key(item['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _remove(item),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(image, style: const TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (spec.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(spec, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('¥${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                            Row(
                              children: [
                                _QuantityButton(icon: Icons.remove, onTap: () => _changeQty(item, qty - 1)),
                                const SizedBox(width: 4),
                                Text('$qty', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                _QuantityButton(icon: Icons.add, onTap: () => _changeQty(item, qty + 1)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalCartFallback() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.items.isEmpty) return _buildEmpty();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (item.spec != null) ...[const SizedBox(height: 4), Text(item.spec!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))],
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('¥${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                              Row(children: [
                                _QuantityButton(icon: Icons.remove, onTap: () => cart.updateQuantity(item.productId, item.quantity - 1)),
                                const SizedBox(width: 4),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                _QuantityButton(icon: Icons.add, onTap: () => cart.updateQuantity(item.productId, item.quantity + 1)),
                              ]),
                            ]),
                          ])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -1))]),
              child: SafeArea(child: Row(children: [
                const Text('合计: ', style: TextStyle(fontSize: 14)),
                Text('¥${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                const Spacer(),
                ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/login'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('登录结算', style: TextStyle(fontSize: 15))),
              ])),
            ),
            const SizedBox(height: 12),
            const Padding(padding: EdgeInsets.all(12), child: Text('未登录购物车仅保存在本机，登录后可同步服务端并结算', style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -1))]),
      child: SafeArea(
        child: Row(
          children: [
            const Text('合计: ', style: TextStyle(fontSize: 14)),
            Text('¥${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _checkout(),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: Text('结算($_count)', style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) return;
    try {
      final res = await ApiClient().dio.post('/api/orders',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
        data: {
          'items': _serverItems.map((i) => {
            'product_id': i['product_id'],
            'quantity': i['quantity'],
            'spec': i['spec'] ?? '',
          }).toList(),
          'address': '{}',
        });
      final orderData = res.data['data'];
      final orderId = orderData['order_id'];
      final total = (orderData['total'] as num?)?.toDouble() ?? _total;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下单成功，去支付')));
        Navigator.push(context, MaterialPageRoute(builder: (_) => PayPage(orderId: orderId, total: total)));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下单失败: $e')));
    }
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}
