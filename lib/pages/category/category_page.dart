import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../widgets/product_card.dart';

class CategoryPage extends StatefulWidget {
  final String? initialCategoryId;
  const CategoryPage({super.key, this.initialCategoryId});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late String _selectedCategoryId;
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loadingCats = true;
  bool _loadingProducts = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? '1';
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiClient().getCategories();
      if (mounted) setState(() { _categories = cats; _loadingCats = false; });
    } catch (e) {
      if (mounted) setState(() { _err = '加载分类失败: $e'; _loadingCats = false; });
    }
  }

  Future<void> _loadProducts() async {
    setState(() { _loadingProducts = true; _err = null; });
    try {
      final list = await ApiClient().getProducts(categoryId: _selectedCategoryId);
      if (mounted) setState(() { _products = list; _loadingProducts = false; });
    } catch (e) {
      if (mounted) setState(() { _err = '加载商品失败: $e'; _loadingProducts = false; });
    }
  }

  void _selectCat(String id) {
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, '/search')),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 80,
            color: Colors.grey[50],
            child: _loadingCats
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = _selectedCategoryId == cat.id;
                    return GestureDetector(
                      onTap: () => _selectCat(cat.id),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          border: Border(left: BorderSide(color: selected ? AppTheme.primaryColor : Colors.transparent, width: 3)),
                        ),
                        child: Text(cat.name, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppTheme.primaryColor : Colors.black87)),
                      ),
                    );
                  },
                ),
          ),
          Expanded(
            child: _loadingProducts
              ? const Center(child: CircularProgressIndicator())
              : (_err != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_err!, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 12), ElevatedButton(onPressed: _loadProducts, child: const Text('重试'))]))
                : (_products.isEmpty
                  ? const Center(child: Text('暂无商品', style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _products.length,
                      itemBuilder: (context, index) => ProductCard(
                        product: _products[index],
                        onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: _products[index]),
                      ),
                    ))),
          ),
        ],
      ),
    );
  }
}
