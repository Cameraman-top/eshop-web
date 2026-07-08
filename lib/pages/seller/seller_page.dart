import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    try {
      final res = await ApiClient().dio.get('/api/my/products',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _products = List<Map<String, dynamic>>.from((res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    final user = context.read<UserProvider>();
    try {
      await ApiClient().dio.post('/api/product/delete', data: {'id': id},
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      _load();
    } catch (_) {}
  }

  void _edit(Map<String, dynamic>? product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditPage(product: product))).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    if (!user.isLoggedIn) return Scaffold(appBar: AppBar(title: const Text('卖家中心')), body: Center(child: Text('请先登录', style: TextStyle(color: Colors.grey[400]))));
    return Scaffold(
      appBar: AppBar(title: const Text('卖家中心')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('发布商品'),
        backgroundColor: const Color(0xFFFF4D4F),
        foregroundColor: Colors.white,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _products.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.store_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('还没有发布商品', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _edit(null), child: const Text('发布第一件商品')),
          ]))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final p = _products[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Center(child: Text(p['image'] ?? '📦', style: const TextStyle(fontSize: 24)))),
                    title: Text(p['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    subtitle: Row(children: [
                      Text('¥${p['price']}', style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Text('库存${p['stock']}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                      Text(p['status'] == 1 ? '在售' : '已下架', style: TextStyle(fontSize: 12, color: p['status'] == 1 ? Colors.green : Colors.grey)),
                    ]),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('下架', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _edit(p);
                        if (v == 'delete') _delete(p['id']);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}

// Product add/edit form
class ProductEditPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductEditPage({super.key, this.product});
  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _desc, _price, _origPrice, _stock;
  final _emojis = ['📦','📱','👕','👟','💄','🍜','🎧','⌚','👜','🎮','📚','🏠','💊','🍷','🎁'];
  String _image = '📦';
  int _catId = 1;
  bool _saving = false;
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] ?? '');
    _desc = TextEditingController(text: p?['description'] ?? '');
    _price = TextEditingController(text: p?['price']?.toString() ?? '');
    _origPrice = TextEditingController(text: p?['original_price']?.toString() ?? '');
    _stock = TextEditingController(text: p?['stock']?.toString() ?? '999');
    _image = p?['image'] ?? '📦';
    _catId = p?['category_id'] ?? 1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = context.read<UserProvider>();
    final data = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'original_price': double.tryParse(_origPrice.text) ?? 0,
      'image': _image,
      'category_id': _catId,
      'stock': int.tryParse(_stock.text) ?? 999,
    };
    if (_isEdit) data['id'] = widget.product!['id'];
    final path = _isEdit ? '/api/product/edit' : '/api/product/add';
    try {
      await ApiClient().dio.post(path, data: data,
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑商品' : '发布商品')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Image picker (emoji)
          Text('商品图标', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _emojis.map((e) => GestureDetector(
            onTap: () => setState(() => _image = e),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _image == e ? const Color(0xFFFF4D4F) : Colors.grey[300]!, width: 2)),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
            ),
          )).toList()),
          const SizedBox(height: 16),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: '商品名称*'), validator: (v) => v!.trim().isEmpty ? '必填' : null),
          TextFormField(controller: _desc, decoration: const InputDecoration(labelText: '商品描述'), maxLines: 3),
          Row(children: [
            Expanded(child: TextFormField(controller: _price, decoration: const InputDecoration(labelText: '售价*'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? '必填' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _origPrice, decoration: const InputDecoration(labelText: '原价'), keyboardType: TextInputType.number)),
          ]),
          TextFormField(controller: _stock, decoration: const InputDecoration(labelText: '库存'), keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_saving ? '保存中...' : _isEdit ? '保存修改' : '立即发布', style: const TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _price.dispose(); _origPrice.dispose(); _stock.dispose();
    super.dispose();
  }
}
