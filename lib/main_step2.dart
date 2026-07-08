import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

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
        home: Scaffold(
          appBar: AppBar(title: const Text('eShop')),
          body: const Center(child: Text('Home', style: TextStyle(fontSize: 24))),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '分类'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '购物车'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        ),
      ),
    );
  }
}
