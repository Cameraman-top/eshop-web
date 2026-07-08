import 'package:flutter/material.dart';

void main() => runApp(const EShopApp());

class EShopApp extends StatelessWidget {
  const EShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eShop',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('eShop')),
        body: const Center(child: Text('商城首页', style: TextStyle(fontSize: 24))),
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
    );
  }
}
