import '../models/product.dart';
import '../models/category.dart';

class MockData {
  static final List<Category> categories = [
    Category(id: '1', name: '手机', icon: '📱'),
    Category(id: '2', name: '电脑', icon: '💻'),
    Category(id: '3', name: '耳机', icon: '🎧'),
    Category(id: '4', name: '手表', icon: '⌚'),
    Category(id: '5', name: '平板', icon: '📋'),
    Category(id: '6', name: '相机', icon: '📷'),
    Category(id: '7', name: '配件', icon: '🔌'),
    Category(id: '8', name: '家居', icon: '🏠'),
  ];

  static final List<String> banners = [
    'https://picsum.photos/seed/banner1/800/300',
    'https://picsum.photos/seed/banner2/800/300',
    'https://picsum.photos/seed/banner3/800/300',
  ];

  static final List<Product> products = [
    Product(
      id: '1',
      name: 'iPhone 15 Pro Max 256GB',
      description: 'A17 Pro 芯片，钛金属设计，4800 万像素主摄',
      price: 8999,
      originalPrice: 9999,
      images: [
        'https://picsum.photos/seed/iphone1/400/400',
        'https://picsum.photos/seed/iphone2/400/400',
        'https://picsum.photos/seed/iphone3/400/400',
      ],
      categoryId: '1',
      sales: 12340,
      rating: 4.8,
      specs: ['256GB', '512GB', '1TB'],
    ),
    Product(
      id: '2',
      name: 'MacBook Pro 14" M3 Pro',
      description: '18GB 内存 / 512GB 存储，Liquid Retina XDR 显示屏',
      price: 12999,
      originalPrice: 14999,
      images: [
        'https://picsum.photos/seed/macbook1/400/400',
        'https://picsum.photos/seed/macbook2/400/400',
      ],
      categoryId: '2',
      sales: 8560,
      rating: 4.9,
      specs: ['18GB', '36GB'],
    ),
    Product(
      id: '3',
      name: 'AirPods Pro 第二代',
      description: '自适应音频，USB-C 充电盒，主动降噪',
      price: 1799,
      originalPrice: 1899,
      images: [
        'https://picsum.photos/seed/airpods1/400/400',
        'https://picsum.photos/seed/airpods2/400/400',
      ],
      categoryId: '3',
      sales: 25600,
      rating: 4.7,
    ),
    Product(
      id: '4',
      name: 'Apple Watch Ultra 2',
      description: '49mm 钛金属表壳，精准双频 GPS，2000 尼特亮度',
      price: 6299,
      originalPrice: 6499,
      images: [
        'https://picsum.photos/seed/watch1/400/400',
        'https://picsum.photos/seed/watch2/400/400',
      ],
      categoryId: '4',
      sales: 4320,
      rating: 4.9,
      specs: ['海洋表带', '野径回环', '高山回环'],
    ),
    Product(
      id: '5',
      name: 'iPad Pro M4 11"',
      description: '超视网膜 XDR 显示屏，M4 芯片，Apple Pencil Pro 支持',
      price: 7599,
      originalPrice: 8499,
      images: [
        'https://picsum.photos/seed/ipad1/400/400',
        'https://picsum.photos/seed/ipad2/400/400',
      ],
      categoryId: '5',
      sales: 6780,
      rating: 4.8,
      specs: ['256GB', '512GB', '1TB'],
    ),
    Product(
      id: '6',
      name: 'Sony A7M4 全画幅微单',
      description: '3300 万像素，4K 60p 视频，实时眼部对焦',
      price: 15499,
      originalPrice: 16999,
      images: [
        'https://picsum.photos/seed/sony1/400/400',
        'https://picsum.photos/seed/sony2/400/400',
      ],
      categoryId: '6',
      sales: 3210,
      rating: 4.8,
      specs: ['单机身', '24-70mm 套机', '24-105mm 套机'],
    ),
    Product(
      id: '7',
      name: 'MagSafe 充电器',
      description: '15W 无线快充，兼容 iPhone 12 及以上机型',
      price: 299,
      originalPrice: 329,
      images: ['https://picsum.photos/seed/magsafe/400/400'],
      categoryId: '7',
      sales: 89000,
      rating: 4.5,
    ),
    Product(
      id: '8',
      name: 'Dyson V15 Detect 无绳吸尘器',
      description: '激光探测微尘，LCD 屏实时显示，60 分钟续航',
      price: 4990,
      originalPrice: 5690,
      images: [
        'https://picsum.photos/seed/dyson1/400/400',
        'https://picsum.photos/seed/dyson2/400/400',
      ],
      categoryId: '8',
      sales: 12400,
      rating: 4.7,
    ),
  ];

  static List<Product> getHotProducts() =>
      products.where((p) => p.sales > 5000).toList();

  static List<Product> getProductsByCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();
}
