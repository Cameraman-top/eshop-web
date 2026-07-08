import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'pages/home/home_page.dart';
import 'pages/category/category_page.dart';
import 'pages/cart/cart_page.dart';
import 'pages/profile/profile_page.dart';

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

  final List<Widget> _pages = [
    const HomePage(),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '首页',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: '分类',
              ),
              BottomNavigationBarItem(
                icon: cart.itemCount > 0
                    ? Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart_outlined))
                    : const Icon(Icons.shopping_cart_outlined),
                activeIcon: cart.itemCount > 0
                    ? Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart))
                    : const Icon(Icons.shopping_cart),
                label: '购物车',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          );
        },
      ),
    );
  }
}
