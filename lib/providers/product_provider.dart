import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/mock_data.dart';
import '../services/api_client.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;
  bool _useApi = true; // Toggle between API and mock

  List<Product> get products => _products;
  bool get loading => _loading;

  Future<void> loadProducts({String? categoryId}) async {
    _loading = true;
    notifyListeners();

    try {
      if (_useApi) {
        _products = await ApiClient().getProducts(categoryId: categoryId);
      } else {
        throw Exception('Using mock');
      }
    } catch (e) {
      // Fallback to mock data
      if (categoryId != null && categoryId.isNotEmpty) {
        _products = MockData.getProductsByCategory(categoryId);
      } else {
        _products = MockData.products;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<List<Product>> getHotProducts() async {
    try {
      if (_useApi) {
        return await ApiClient().getHotProducts();
      }
    } catch (_) {}
    return MockData.getHotProducts();
  }
}
