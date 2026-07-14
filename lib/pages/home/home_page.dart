import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBanner = 0;
  int _unread = 0;
  List<Category> _categories = [];
  List<Product> _hot = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
    _checkUnread();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final api = ApiClient();
      final cats = await api.getCategories();
      final hot = await api.getHotProducts();
      if (mounted) setState(() {
        _categories = cats;
        _hot = hot;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _err = '加载失败: $e'; _loading = false; });
    }
  }

  Future<void> _checkUnread() async {
    try {
      final user = context.read<UserProvider>();
      if (!user.isLoggedIn) return;
      final res = await ApiClient().dio.get('/api/notification/unread',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      if (mounted) setState(() => _unread = res.data['data'] ?? 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eShop 商城'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => Navigator.pushNamed(context, '/search')),
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.pushNamed(context, '/notification').then((_) => _checkUnread())),
              if (_unread > 0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFFF4D4F), shape: BoxShape.circle), child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_err != null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_err!, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('重试'))]))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildBanner()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildCategories()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildSectionHeader()),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  _buildProductGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              )),
      ),
    );
  }

  Widget _buildBanner() {
    final bannerColors = [const Color(0xFFFF6B6B), const Color(0xFFFF4D4F), const Color(0xFFFF8E53)];
    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: bannerColors.length,
        onPageChanged: (index) => setState(() => _currentBanner = index),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [bannerColors[index], bannerColors[(index + 1) % bannerColors.length]],
              ),
            ),
            child: const Center(child: Text('🔥 限时特惠', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const SizedBox(height: 90, child: Center(child: Text('暂无分类', style: TextStyle(color: Colors.grey))));
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/category', arguments: cat.id),
            child: Container(
              width: 72, margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 6),
                  Text(cat.name, style: const TextStyle(fontSize: 11, color: Colors.black87), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🔥 热销推荐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/category'), child: Text('查看全部', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_hot.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: Text('暂无热销商品', style: TextStyle(color: Colors.grey)))));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(
            product: _hot[index],
            onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: _hot[index]),
          ),
          childCount: _hot.length,
        ),
      ),
    );
  }
}
