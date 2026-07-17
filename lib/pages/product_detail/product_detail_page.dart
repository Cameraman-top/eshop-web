import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../../config/theme.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSpec = '';
  int _quantity = 1;
  bool _favorited = false;
  List<Map<String, dynamic>> _reviews = [];
  int _reviewPage = 0;
  bool _loadingFav = false;

  @override
  void initState() {
    super.initState();
    _selectedSpec = widget.product.specs.isNotEmpty ? widget.product.specs.first : '';
    _loadReviews();
    _loadFavoriteStatus();
  }

  Future<void> _addToCart(BuildContext ctx, p) async {
    final user = ctx.read<UserProvider>();
    if (!user.isLoggedIn) {
      ctx.read<CartProvider>().addItem(CartItem(
        productId: p.id, name: p.name, price: p.price, image: p.image,
        spec: _selectedSpec.isNotEmpty ? _selectedSpec : null, quantity: _quantity));
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('已加入本地购物车，登录后可同步'), duration: Duration(seconds: 1)));
      return;
    }
    try {
      await ApiClient().addToCart(user.userId!, p.id, spec: _selectedSpec.isNotEmpty ? _selectedSpec : null, quantity: _quantity);
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('已加入购物车'), duration: Duration(seconds: 1)));
    } catch (_) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('加入失败，请重试')));
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await ApiClient().dio.get('/api/reviews', queryParameters: {'product_id': widget.product.id, 'page': _reviewPage});
      final list = (res.data is List) ? res.data : (res.data['data'] as List? ?? []);
      if (mounted) setState(() => _reviews = List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {}
  }

  List<String> _reviewImages(Map<String, dynamic> r) {
    final raw = r['images'];
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    if (raw is String && raw.startsWith('[')) {
      try { return List<String>.from(jsonDecode(raw)); } catch (_) { return []; }
    }
    return [];
  }

  Future<void> _loadFavoriteStatus() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) return;
    try {
      final favs = await ApiClient().getFavorites(user.token!);
      final idStr = widget.product.id;
      final hit = favs.any((f) => f['product_id'].toString() == idStr);
      if (mounted) setState(() => _favorited = hit);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    if (_loadingFav) return;
    setState(() { _favorited = !_favorited; _loadingFav = true; });
    try {
      await ApiClient().toggleFavorite(user.token!, int.parse(widget.product.id), _favorited);
    } catch (_) {
      if (mounted) setState(() => _favorited = !_favorited);
    } finally {
      if (mounted) setState(() => _loadingFav = false);
    }
  }

  void _writeReview() {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    int rating = 5;
    final contentCtrl = TextEditingController();
    List<String> selectedImgs = [];
    const palette = ['💰','🌟','🎁','👍','❤️','🔥','✨','📸','💯'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('写评价', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(children: List.generate(5, (i) => GestureDetector(onTap: () => setModal(() => rating = i + 1), child: Icon(i < rating ? Icons.star : Icons.star_border, size: 32, color: Colors.amber[600])))),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '评价内容', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text('添加图片（emoji）', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: palette.map((e) {
            final on = selectedImgs.contains(e);
            return GestureDetector(onTap: () => setModal(() { if (on) selectedImgs.remove(e); else if (selectedImgs.length < 3) selectedImgs.add(e); }), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: on ? const Color(0xFFFF4D4F).withOpacity(0.12) : Colors.grey[100], border: Border.all(color: on ? const Color(0xFFFF4D4F) : Colors.grey[200]!), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(e, style: const TextStyle(fontSize: 24)))));
          }).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (contentCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写评价内容'))); return; }
              try {
                await ApiClient().addReview(user.token!, int.parse(widget.product.id), rating, contentCtrl.text.trim(), images: selectedImgs);
                if (ctx.mounted) { Navigator.pop(ctx); _loadReviews(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评价成功'), duration: Duration(seconds: 1))); }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('评价失败: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('提交'),
          )),
          const SizedBox(height: 20),
        ]),
      )),
    );
    contentCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        actions: [
          IconButton(icon: Icon(_favorited ? Icons.favorite : Icons.favorite_border, color: _favorited ? const Color(0xFFFF4D4F) : null), onPressed: () => _toggleFavorite()),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Image gallery
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: p.images.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(p.images[index], style: const TextStyle(fontSize: 60))),
                ),
              ),
            ),
          ),
          // Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Text('¥${p.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                  const SizedBox(width: 8),
                  Text('¥${p.originalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFF4D4F).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('库存 ${p.stock}', style: const TextStyle(fontSize: 11, color: Color(0xFFFF4D4F)))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('已售 ${p.sales}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 16),
                  Row(children: [Icon(Icons.star, size: 14, color: Colors.amber[600]), const SizedBox(width: 2), Text('${p.rating}', style: TextStyle(fontSize: 12, color: Colors.amber[600]))]),
                  const SizedBox(width: 16),
                  Text('${_reviews.length}条评价', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ]),
            ),
          ),
          // Quantity selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(children: [
                const Text('数量', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                _qtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                Container(width: 48, alignment: Alignment.center, child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                _qtyBtn(Icons.add, () { if (_quantity < p.stock) setState(() => _quantity++); }),
              ]),
            ),
          ),
          // Specs
          if (p.specs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('规格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 10, children: p.specs.map((spec) => GestureDetector(
                    onTap: () => setState(() => _selectedSpec = spec),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSpec == spec ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                        border: Border.all(color: _selectedSpec == spec ? AppTheme.primaryColor : Colors.transparent, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(spec, style: TextStyle(fontSize: 13, color: _selectedSpec == spec ? AppTheme.primaryColor : Colors.black87)),
                    ),
                  )).toList()),
                ]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('商品描述', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(p.description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6)),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // Reviews
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('商品评价', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(onPressed: _writeReview, icon: const Icon(Icons.edit, size: 16), label: const Text('写评价', style: TextStyle(fontSize: 13))),
                ]),
                if (_reviews.isEmpty)
                  Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('暂无评价', style: TextStyle(color: Colors.grey[400]))))
                else
                  ..._reviews.map((r) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 14, backgroundColor: Colors.grey[200], child: Text((r['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 10))),
                        const SizedBox(width: 8),
                        Text(r['nickname'] ?? '匿名', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Row(children: List.generate(r['rating'] ?? 5, (_) => Icon(Icons.star, size: 12, color: Colors.amber[600]))),
                      ]),
                      if ((r['content'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r['content'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                      if (_reviewImages(r).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 6, runSpacing: 6, children: _reviewImages(r).map((img) => Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Center(child: Text(img, style: const TextStyle(fontSize: 32))))).toList())),
                      Padding(padding: const EdgeInsets.only(top: 4), child: Text(r['created_at'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
                    ]),
                  )),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -1))]),
        child: SafeArea(
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => Navigator.pushNamed(context, '/chat')),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addToCart(context, p),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4D4F), side: const BorderSide(color: Color(0xFFFF4D4F)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: const Text('加入购物车', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _buyNow(context, p),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: const Text('立即购买', style: TextStyle(fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }

  void _buyNow(BuildContext context, Product p) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      final result = await Navigator.pushNamed(context, '/login');
      if (result != true || !user.isLoggedIn) return;
    }
    try {
      final api = ApiClient();
      final result = await api.createOrder(
        user.token!,
        [{'product_id': int.parse(p.id), 'quantity': _quantity, 'spec': _selectedSpec.isNotEmpty ? _selectedSpec : ''}],
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下单成功！订单号: ${result['order_no']}')));
      Navigator.pushNamed(context, '/orders');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下单失败: $e')));
    }
  }
}
