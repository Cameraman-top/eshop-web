import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6B6B), Color(0xFFFF4D4F)]),
                  ),
                ),
                Positioned(
                  top: 50, right: 8,
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.mail_outline, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30, left: 24, right: 24,
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                        child: Icon(user.isLoggedIn ? Icons.person : Icons.person_outline, size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isLoggedIn ? 'Hi, ${user.nickname}' : 'Hi, 欢迎回来',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isLoggedIn ? user.phone : '登录后享受更多优惠',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (user.isLoggedIn) {
                            user.logout();
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(user.isLoggedIn ? '退出' : '登录/注册', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // Order section
          SliverToBoxAdapter(
            child: _buildSection(context, '我的订单', '查看全部 >', () => Navigator.pushNamed(context, '/orders'), [
              _orderAction(Icons.payment_outlined, '待付款'),
              _orderAction(Icons.local_shipping_outlined, '待发货'),
              _orderAction(Icons.inventory_2_outlined, '待收货'),
              _orderAction(Icons.rate_review_outlined, '待评价'),
              _orderAction(Icons.replay_outlined, '售后'),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Menu
          SliverToBoxAdapter(
            child: _buildMenuCard([
              _menuItem(Icons.favorite_border, '我的收藏', () {}),
              _menuItem(Icons.location_on_outlined, '收货地址', () => Navigator.pushNamed(context, '/address')),
              _menuItem(Icons.monetization_on_outlined, '分销中心', () => Navigator.pushNamed(context, '/referral')),
              _menuItem(Icons.store_outlined, '卖家中心', () => Navigator.pushNamed(context, '/seller')),
              _menuItem(Icons.card_giftcard_outlined, '优惠券', () => Navigator.pushNamed(context, '/coupon')),
              _menuItem(Icons.flash_on_outlined, '限时秒杀', () => Navigator.pushNamed(context, '/seckill')),
              _menuItem(Icons.live_tv_outlined, '直播', () => Navigator.pushNamed(context, '/live')),
              _menuItem(Icons.headset_mic_outlined, '联系客服', () => Navigator.pushNamed(context, '/chat')),
              _menuItem(Icons.support_agent_outlined, '帮助中心', () {}),
              _menuItem(Icons.info_outline, '关于我们', () {}),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String action, VoidCallback onAction, List<Widget> actions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(onPressed: onAction, child: Text(action, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: actions),
        ],
      ),
    );
  }

  Widget _orderAction(IconData icon, String label) {
    return Column(children: [
      Icon(icon, size: 24, color: Colors.black87),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
      onTap: onTap,
    );
  }
}
