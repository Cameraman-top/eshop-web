import 'package:flutter_test/flutter_test.dart';
import 'package:eshop_flutter/models/product.dart';

void main() {
  test('Product.fromJson parses fields and computes discount', () {
    final p = Product.fromJson({
      'id': 7,
      'name': 'Phone',
      'price': 80,
      'original_price': 100,
      'category_id': 2,
      'specs': ['64G', 'Black'],
    });
    expect(p.id, '7');
    expect(p.name, 'Phone');
    expect(p.price, 80);
    expect(p.originalPrice, 100);
    expect(p.categoryId, '2');
    expect(p.specs, ['64G', 'Black']);
    expect(p.discount, closeTo(0.2, 1e-9));
    expect(p.discountText, '20% OFF');
  });

  test('Product.fromJson tolerates missing optional fields', () {
    final p = Product.fromJson({'id': 1, 'name': 'X', 'price': 10});
    expect(p.originalPrice, 0);
    expect(p.discount, 0);
    expect(p.specs, isEmpty);
  });
}
