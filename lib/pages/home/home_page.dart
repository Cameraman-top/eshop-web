import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../services/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _checkUnread();
  }

  Future<void> _checkUnread() async {
    try {
      final user = context.read<UserProvider>();
      if (!user.isLoggedIn) return;
      final res = await ApiClient().dio.get('/api/notification/unread',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
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
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            // Banner
            SliverToBoxAdapter(child: _buildBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Categories
            SliverToBoxAdapter(child: _buildCategories()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Section header
            SliverToBoxAdapter(child: _buildSectionHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Product grid
            _buildProductGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: MockData.categories.length,
        itemBuilder: (context, index) {
          final cat = MockData.categories[index];
          return GestureDetector(
            onTap: () {},
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
          TextButton(onPressed: () {}, child: Text('查看全部', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final hotProducts = MockData.getHotProducts();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(
            product: hotProducts[index],
            onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: hotProducts[index]),
          ),
          childCount: hotProducts.length,
        ),
      ),
    );
  }
}
