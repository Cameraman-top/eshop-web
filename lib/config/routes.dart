import 'package:flutter/material.dart';
import '../pages/home/home_page.dart';
import '../pages/category/category_page.dart';
import '../pages/cart/cart_page.dart';
import '../pages/order/order_page.dart';
import '../pages/profile/profile_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String category = '/category';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomePage(),
    category: (_) => const CategoryPage(),
    cart: (_) => const CartPage(),
    orders: (_) => const OrderPage(),
    profile: (_) => const ProfilePage(),
  };
}
