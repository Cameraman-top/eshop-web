import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import 'package:dio/dio.dart';

class PayPage extends StatefulWidget {
  final int orderId;
  final double total;
  const PayPage({super.key, required this.orderId, required this.total});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  bool _paying = false;
  String _method = 'balance';

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final user = context.read<UserProvider>();
      final res = await ApiClient().dio.post('/api/order/pay',
        data: {'order_id': widget.orderId},
        options: _authOptions(user.token!),
      );
      if (res.data['code'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('支付成功！')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('支付失败: $e')));
    }
    setState(() => _paying = false);
  }

  Options _authOptions(String token) =>
    Options(headers: {'Authorization': 'Bearer $token'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认支付')),
      body: Column(children: [
        const SizedBox(height: 40),
        const Icon(Icons.payment, size: 60, color: Color(0xFFFF4D4F)),
        const SizedBox(height: 16),
        Text('¥${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('订单号: ${widget.orderId}', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            _payMethod('balance', '余额支付', '¥2,380.00', Icons.account_balance_wallet),
            _payMethod('card', '银行卡支付', '', Icons.credit_card),
            _payMethod('alipay', '支付宝', '', Icons.qr_code),
            _payMethod('wechat', '微信支付', '', Icons.chat),
          ]),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _paying ? null : _pay,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _paying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('立即支付', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _payMethod(String value, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _method == value ? const Color(0xFFFF4D4F) : Colors.grey),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Radio<String>(value: value, groupValue: _method, onChanged: (v) => setState(() => _method = v!)),
      onTap: () => setState(() => _method = value),
    );
  }
}
