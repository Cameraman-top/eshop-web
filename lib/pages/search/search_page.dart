import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../models/product.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _suggestions = [];
  List<String> _history = [];
  List<String> _hot = [];
  List<Product> _results = [];
  bool _searching = false;
  bool _showResults = false;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadInit();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInit() async {
    final user = context.read<UserProvider>();
    final api = ApiClient();
    try {
      final hot = await api.dio.get('/api/search/hot');
      _hot = (hot.data['data'] as List).cast<String>();
    } catch (_) {}
    if (user.isLoggedIn) {
      try {
        final hist = await api.dio.get('/api/search/history', options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
        _history = (hist.data['data'] as List).cast<String>();
      } catch (_) {}
    }
    setState(() {});
  }

  Future<void> _onChanged(String q) async {
    _keyword = q;
    if (q.isEmpty) {
      setState(() { _suggestions = []; _showResults = false; });
      return;
    }
    try {
      final res = await ApiClient().dio.get('/api/search/suggest', queryParameters: {'q': q});
      _suggestions = (res.data['data'] as List).cast<String>();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    _keyword = q;
    _controller.text = q;
    _focusNode.unfocus();
    setState(() { _searching = true; _showResults = true; });
    // Save to history
    final user = context.read<UserProvider>();
    if (user.isLoggedIn) {
      try {
        await ApiClient().dio.post('/api/search/history', data: {'keyword': q}, options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      } catch (_) {}
    }
    try {
      final res = await ApiClient().dio.get('/api/search', queryParameters: {'q': q});
      final data = res.data['data'] as List;
      _results = data.map((j) => Product.fromJson(j)).toList();
    } catch (_) {}
    setState(() => _searching = false);
  }

  void _clearHistory() {
    _history.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: '搜索商品',
            border: InputBorder.none,
            suffixIcon: _keyword.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _controller.clear(); _onChanged(''); }) : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => _search(_controller.text), child: const Text('搜索', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: _showResults
        ? _buildResults()
        : _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Suggestions dropdown
        if (_suggestions.isNotEmpty)
          ..._suggestions.map((s) => ListTile(
            leading: const Icon(Icons.search, size: 20, color: Colors.grey),
            title: Text(s, style: const TextStyle(fontSize: 14)),
            dense: true,
            onTap: () => _search(s),
          )),
        const SizedBox(height: 16),
        // Search history
        if (_history.isNotEmpty) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(onPressed: _clearHistory, child: const Text('清空', style: TextStyle(fontSize: 12))),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: _history.map((h) => ActionChip(
            label: Text(h, style: const TextStyle(fontSize: 13)),
            avatar: const Icon(Icons.history, size: 14),
            onPressed: () => _search(h),
          )).toList()),
          const SizedBox(height: 24),
        ],
        // Hot searches
        if (_hot.isNotEmpty) ...[
          const Text('热门搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _hot.asMap().entries.map((e) => ActionChip(
            label: Text(e.value, style: const TextStyle(fontSize: 13)),
            avatar: Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: e.key < 3 ? const Color(0xFFFF4D4F) : Colors.grey)),
            onPressed: () => _search(e.value),
          )).toList()),
        ],
      ],
    );
  }

  Widget _buildResults() {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (_results.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('未找到"$_keyword"相关商品', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
    ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text('找到 ${_results.length} 件商品', style: TextStyle(color: Colors.grey[500], fontSize: 13))),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: _results.length,
        itemBuilder: (ctx, i) => _productCard(_results[i]),
      )),
    ]);
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: p),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Center(child: Text(p.image, style: const TextStyle(fontSize: 48))))),
          Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              Text('¥${p.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
              const SizedBox(width: 6),
              Text('${p.sales}人买过', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
          ])),
        ]),
      ),
    );
  }
}
