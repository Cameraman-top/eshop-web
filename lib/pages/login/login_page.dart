import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '13800138000');
  final _pwdController = TextEditingController(text: '123456');
  bool _isLogin = true;

  void _submit() async {
    final phone = _phoneController.text.trim();
    final pwd = _pwdController.text.trim();
    if (phone.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整')));
      return;
    }
    final provider = context.read<UserProvider>();
    final result = _isLogin
        ? await provider.login(phone, pwd)
        : await provider.register(phone, pwd);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['msg'] ?? '操作失败')));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录' : '注册')),
      body: Consumer<UserProvider>(
        builder: (context, user, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_bag, size: 64, color: Color(0xFFFF4D4F)),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_android), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwdController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: user.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: user.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isLogin ? '登录' : '注册', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
              ),
            ]),
          );
        },
      ),
    );
  }
}
