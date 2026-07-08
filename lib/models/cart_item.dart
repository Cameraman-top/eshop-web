class CartItem {
  final String productId;
  final String name;
  final String image;
  final double price;
  int quantity;
  final String? spec;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
    this.spec,
  });

  double get total => price * quantity;
}
