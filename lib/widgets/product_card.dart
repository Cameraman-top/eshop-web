import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final img = product.images.isNotEmpty ? product.images.first : product.image;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _isUrl(img)
                ? CachedNetworkImage(
                    imageUrl: img,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 140, color: Colors.grey[100]),
                    errorWidget: (_, __, ___) => Container(height: 140, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  )
                : Container(
                    height: 140,
                    width: double.infinity,
                    color: const Color(0xFFFFF1F0),
                    child: Center(child: Text(img.isEmpty ? '📦' : img, style: const TextStyle(fontSize: 56))),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('¥${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D4F))),
                    if (product.discount > 0) ...[
                      const SizedBox(width: 6),
                      Text('¥${product.originalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text('已售 ${_formatSales(product.sales)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSales(int sales) {
    if (sales >= 10000) return '${(sales / 10000).toStringAsFixed(1)}万';
    if (sales >= 1000) return '${(sales / 1000).toStringAsFixed(1)}k';
    return sales.toString();
  }
}
