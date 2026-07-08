import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/mock_data.dart';
import '../../widgets/product_card.dart';

void main() => runApp(const EShopApp());

class EShopApp extends StatelessWidget {
  const EShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'eShop',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eShop')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
        slivers: [
          // Step 1: just a simple text
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(child: Text('Step 1: CustomScrollView works', style: TextStyle(fontSize: 20))),
            ),
          ),
          // Step 2: categories
          SliverToBoxAdapter(child: _buildCategories()),
          // Step 3: product grid
          _buildProductGrid(),
        ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '分类'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '购物车'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
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
          return Container(
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(height: 6),
                Text(cat.name, style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const SliverToBoxAdapter(
            child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          );
        }
        final hotProducts = MockData.getHotProducts();
        return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(
            product: hotProducts[index],
            onTap: () {},
          ),
          childCount: hotProducts.length,
        ),
        ),
      );
      },
    );
  }
}
