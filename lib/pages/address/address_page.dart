import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import 'package:dio/dio.dart';

class AddressPage extends StatefulWidget {
  final bool selectMode;
  const AddressPage({super.key, this.selectMode = false});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>();
    try {
      final res = await ApiClient().dio.get('/api/addresses',
        options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
      );
      setState(() {
        _addresses = (res.data['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final user = context.read<UserProvider>();
    await ApiClient().dio.post('/api/address/delete',
      data: {'id': id},
      options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
    );
    _load();
  }

  Future<void> _setDefault(int id) async {
    final user = context.read<UserProvider>();
    await ApiClient().dio.post('/api/address/update',
      data: {'id': id, 'is_default': 1},
      options: Options(headers: {'Authorization': 'Bearer ${user.token}'}),
    );
    _load();
  }

  void _edit([Map<String, dynamic>? addr]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddressEditPage(address: addr))).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收货地址')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        backgroundColor: const Color(0xFFFF4D4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _addresses.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('暂无地址', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _addresses.length,
              itemBuilder: (ctx, i) {
                final a = _addresses[i];
                final isDefault = a['is_default'] == 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: widget.selectMode ? () => Navigator.pop(context, a) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(width: 12),
                          Text(a['phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                          if (isDefault) ...[
                            const Spacer(),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFF4D4F).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('默认', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 11))),
                          ],
                        ]),
                        const SizedBox(height: 6),
                        Text('${a['province'] ?? ''} ${a['city'] ?? ''} ${a['district'] ?? ''} ${a['detail'] ?? ''}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          TextButton(onPressed: () => _edit(a), child: const Text('编辑')),
                          if (!isDefault) TextButton(onPressed: () => _setDefault(a['id']), child: const Text('设为默认')),
                          TextButton(onPressed: () => _delete(a['id']), child: const Text('删除', style: TextStyle(color: Colors.red))),
                        ]),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AddressEditPage extends StatefulWidget {
  final Map<String, dynamic>? address;
  const AddressEditPage({super.key, this.address});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _detail = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final a = widget.address!;
      _name.text = a['name'] ?? '';
      _phone.text = a['phone'] ?? '';
      _province.text = a['province'] ?? '';
      _city.text = a['city'] ?? '';
      _district.text = a['district'] ?? '';
      _detail.text = a['detail'] ?? '';
      _isDefault = a['is_default'] == 1;
    }
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _province.dispose(); _city.dispose(); _district.dispose(); _detail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<UserProvider>();
    final data = {
      'name': _name.text, 'phone': _phone.text,
      'province': _province.text, 'city': _city.text, 'district': _district.text,
      'detail': _detail.text, 'is_default': _isDefault ? 1 : 0,
    };
    try {
      if (widget.address != null) {
        data['id'] = widget.address!['id'];
        await ApiClient().dio.post('/api/address/update', data: data, options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      } else {
        await ApiClient().dio.post('/api/address/add', data: data, options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.address != null ? '编辑地址' : '新增地址')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _field('收货人', _name),
        _field('手机号', _phone, keyboardType: TextInputType.phone),
        _field('省', _province),
        _field('市', _city),
        _field('区', _district),
        _field('详细地址', _detail, maxLines: 2),
        const SizedBox(height: 12),
        SwitchListTile(title: const Text('设为默认地址'), value: _isDefault, onChanged: (v) => setState(() => _isDefault = v)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F)), child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)))),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}
