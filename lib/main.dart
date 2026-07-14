import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'models/product.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/user_provider.dart';
import 'pages/home/home_page.dart';
import 'pages/category/category_page.dart';
import 'pages/cart/cart_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/product_detail/product_detail_page.dart';
import 'pages/order/order_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/login/login_page.dart';
import 'pages/social/social_page.dart';
import 'pages/group_buy/group_buy_page.dart';
import 'pages/seckill/seckill_page.dart';
import 'pages/coupon/coupon_page.dart';
import 'pages/live/live_page.dart';
import 'pages/order/pay_page.dart';
import 'pages/order/order_detail_page.dart';
import 'pages/address/address_page.dart';
import 'pages/search/search_page.dart';
import 'pages/notification/notification_page.dart';
import 'pages/profile/user_profile_page.dart';
import 'pages/profile/referral_page.dart';
import 'pages/seller/seller_page.dart';
import 'pages/video/video_page.dart';
import 'pages/video/video_upload_page.dart';

void main() => runApp(const EShopApp());

class EShopApp extends StatelessWidget {
  const EShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'eShop 社交商城',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/product_detail':
              final product = settings.arguments as Product;
              return MaterialPageRoute(builder: (_) => ProductDetailPage(product: product));
            case '/category':
              final catId = settings.arguments is String ? settings.arguments as String : null;
              return MaterialPageRoute(builder: (_) => CategoryPage(initialCategoryId: catId));
            case '/orders':
              return MaterialPageRoute(builder: (_) => const OrderPage());
            case '/chat':
              return MaterialPageRoute(builder: (_) => const ChatPage());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/social':
              return MaterialPageRoute(builder: (_) => const SocialPage());
            case '/group_buy':
              return MaterialPageRoute(builder: (_) => const GroupBuyPage());
            case '/seckill':
              return MaterialPageRoute(builder: (_) => const SeckillPage());
            case '/coupon':
              return MaterialPageRoute(builder: (_) => const CouponPage());
            case '/live':
              return MaterialPageRoute(builder: (_) => const LivePage());
            case '/address':
              return MaterialPageRoute(builder: (_) => const AddressPage());
            case '/search':
              return MaterialPageRoute(builder: (_) => const SearchPage());
            case '/notification':
              return MaterialPageRoute(builder: (_) => const NotificationPage());
            case '/referral':
              return MaterialPageRoute(builder: (_) => const ReferralPage());
            case '/seller':
              return MaterialPageRoute(builder: (_) => const SellerPage());
            case '/video/upload':
              return MaterialPageRoute(builder: (_) => const VideoUploadPage());
            default:
              return MaterialPageRoute(builder: (_) => const MainShell());
          }
        },
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

  List<Widget> get _pages => [
    const HomePage(),
    const SocialPage(),
    VideoPage(isActive: _currentIndex == 2),
    const GroupBuyPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首页'),
              const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: '种草'),
              const BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), activeIcon: Icon(Icons.play_circle_filled), label: '短视频'),
              const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: '拼团'),
              BottomNavigationBarItem(
                icon: cart.itemCount > 0 ? Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart_outlined)) : const Icon(Icons.shopping_cart_outlined),
                activeIcon: cart.itemCount > 0 ? Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart)) : const Icon(Icons.shopping_cart),
                label: '购物车',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '我的'),
            ],
          );
        },
      ),
    );
  }
}
