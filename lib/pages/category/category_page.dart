import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../widgets/product_card.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String _selectedCategoryId = '1';

  @override
  Widget build(BuildContext context) {
    final products = MockData.getProductsByCategory(_selectedCategoryId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 80,
            color: Colors.grey[50],
            child: ListView.builder(
              itemCount: MockData.categories.length,
              itemBuilder: (context, index) {
                final cat = MockData.categories[index];
                final selected = _selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
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
          // Right content
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('暂无商品', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(
                      product: products[index],
                      onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: products[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
