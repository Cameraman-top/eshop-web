import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:html' if (dart.library.io) 'dart:io';
import '../models/product.dart';
import '../models/category.dart';

String _getBaseUrl() {
  try {
    final url = window.localStorage['API_BASE_URL'];
    if (url != null && url.isNotEmpty) return url;
  } catch (_) {}
  return const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://eshop-api-l86g.onrender.com');
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  late final Dio _chatDio;
  Dio get dio => _dio;

  static String get baseUrl => _getBaseUrl();
  static String get chatBaseUrl => _getBaseUrl();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
    _chatDio = Dio(BaseOptions(
      baseUrl: chatBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
    _addRetry(_dio);
    _addRetry(_chatDio);
  }

  void _addRetry(Dio d) {
    d.interceptors.add(InterceptorsWrapper(
      onError: (e, h) async {
        final retried = e.requestOptions.extra['retried'] == true;
        final retriable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (retried || !retriable) return h.reject(e);
        e.requestOptions.extra['retried'] = true;
        try {
          return h.resolve(await d.fetch(e.requestOptions));
        } catch (e2) {
          return h.reject(e2 as DioException);
        }
      },
    ));
  }

  // ===== Products =====
  Future<List<Product>> getProducts({String? categoryId, String? keyword, int page = 1}) async {
    final params = <String, dynamic>{'page': page, 'limit': 20};
    if (categoryId != null && categoryId.isNotEmpty) params['category_id'] = categoryId;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final res = await _dio.get('/api/products', queryParameters: params);
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((json) => Product(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      images: [json['image']?.toString() ?? ''],
      categoryId: (json['category_id'] ?? 1).toString(),
      sales: json['sales'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      specs: _parseSpecs(json['specs']),
    )).toList();
  }

  List<String> _parseSpecs(dynamic specs) {
    if (specs is List) return specs.map((e) => e.toString()).toList();
    if (specs is String && specs.startsWith('[')) {
      try {
        return (jsonDecode(specs) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<List<Product>> getHotProducts() async {
    final res = await _dio.get('/api/products/hot');
    final list = (res.data is List) ? res.data as List : (res.data['data'] as List? ?? []);
    return list.map((json) => Product(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      images: [json['image']?.toString() ?? ''],
      categoryId: (json['category_id'] ?? 1).toString(),
      sales: json['sales'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      specs: _parseSpecs(json['specs']),
    )).toList();
  }

  Future<Product?> getProduct(String id) async {
    try {
      final res = await _dio.get('/api/products/$id');
      final json = res.data['data'];
      return Product(
        id: json['id'].toString(),
        name: json['name'],
        description: json['description'] ?? '',
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['original_price'] as num).toDouble(),
        images: List<String>.from(json['images'] ?? []),
        categoryId: json['category_id'].toString(),
        sales: json['sales'] ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        specs: List<String>.from(json['specs'] ?? []),
      );
    } catch (e) {
      return null;
    }
  }

  // ===== Categories =====
  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/api/categories');
    final list = (res.data['data'] as List);
    return list.map((json) => Category(
      id: json['id'].toString(),
      name: json['name'],
      icon: json['icon'] ?? '📦',
    )).toList();
  }

  // ===== Cart =====
  Future<List<Map<String, dynamic>>> getCart(int userId) async {
    final res = await _dio.get('/api/cart/$userId');
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<void> addToCart(int userId, String productId, {String? spec, int quantity = 1}) async {
    await _dio.post('/api/cart', data: {
      'user_id': userId,
      'product_id': int.parse(productId),
      'spec': spec,
      'quantity': quantity,
    });
  }

  Future<void> updateCartItem(int id, int quantity) async {
    await _dio.put('/api/cart', data: {'id': id, 'quantity': quantity});
  }

  Future<void> removeCartItem(int id) async {
    await _dio.delete('/api/cart', data: {'id': id});
  }

  // ===== Orders =====
  Future<List<Map<String, dynamic>>> getOrders(String token) async {
    final res = await _dio.get('/api/orders', options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createOrder(String token, List<Map<String, dynamic>> items, {String address = ''}) async {
    final res = await _dio.post('/api/orders',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'items': items, 'address': address},
    );
    return res.data['data'] ?? res.data;
  }

  // ===== User =====
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await _dio.post('/api/user/login', data: {'phone': phone, 'password': password});
      return res.data['data'];
    } on DioException catch (e) {
      throw Exception(_srvMsg(e));
    }
  }

  Future<Map<String, dynamic>> register(String phone, String password, {String? nickname}) async {
    try {
      final res = await _dio.post('/api/user/register', data: {'phone': phone, 'password': password, 'nickname': nickname});
      return res.data['data'];
    } on DioException catch (e) {
      throw Exception(_srvMsg(e));
    }
  }

  String _srvMsg(DioException e) {
    final d = e.response?.data;
    if (d is Map && d['msg'] is String) return d['msg'] as String;
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) return '网络连接失败，请稍后重试';
    return '请求失败 (${e.response?.statusCode ?? '?'})';
  }

  // ===== Chat =====
  Future<List<ChatMessageDTO>> getChatMessages(int sessionId) async {
    final res = await _chatDio.get('', queryParameters: {
      'action': 'messages',
      'session_id': sessionId,
    });
    final list = (res.data['data'] as List);
    return list.map((m) => ChatMessageDTO(
      id: m['id'],
      content: m['content'],
      senderType: m['sender_type'],
    )).toList();
  }

  Future<Map<String, dynamic>> sendChatMessage({
    int? sessionId,
    required String content,
    required String senderType,
    String? userName,
  }) async {
    final params = <String, dynamic>{'action': 'messages'};
    if (sessionId != null) params['session_id'] = sessionId;
    final res = await _chatDio.post('', queryParameters: params, data: {
      'content': content,
      'sender_type': senderType,
      'user_name': userName,
    });
    return res.data['data'];
  }

  // ===== Social =====
  Future<List<Map<String, dynamic>>> getPosts({int? topicId}) async {
    final params = <String, dynamic>{};
    if (topicId != null && topicId > 0) params['topic_id'] = topicId;
    final res = await _dio.get('/api/posts', queryParameters: params);
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createPost(String token, String content, {String title = '', int topicId = 0}) async {
    final res = await _dio.post('/api/posts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'title': title, 'content': content, 'topic_id': topicId, 'action': 'create'},
    );
    return res.data;
  }

  Future<Map<String, dynamic>?> getPostDetail(int id) async {
    final res = await _dio.get('/api/posts/$id');
    final d = res.data;
    if (d is Map<String, dynamic>) return d;
    if (d is List) return null;
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  Future<void> addComment(int postId, String token, String content, {int parentId = 0}) async {
    await _dio.post('/api/comments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'post_id': postId, 'content': content, 'parent_id': parentId},
    );
  }

  Future<void> follow(int targetId, String token, {bool unfollow = false}) async {
    await _dio.post('/api/follow',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'action': unfollow ? 'unfollow' : 'follow', 'target_id': targetId},
    );
  }

  Future<List<Map<String, dynamic>>> getFollowers(int userId) async {
    final res = await _dio.get('/api/followers', queryParameters: {'user_id': userId});
    final d = res.data;
    final data = d is List ? d : (d is Map ? d['data'] : null);
    return List<Map<String, dynamic>>.from((data as List?) ?? []);
  }

  Future<List<Map<String, dynamic>>> getFollowing(int userId) async {
    final res = await _dio.get('/api/following', queryParameters: {'user_id': userId});
    final d = res.data;
    final data = d is List ? d : (d is Map ? d['data'] : null);
    return List<Map<String, dynamic>>.from((data as List?) ?? []);
  }

  Future<void> toggleLike(int postId, String token, bool like) async {
    await _dio.post('/api/like',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'post_id': postId, 'action': like ? 'like' : 'unlike'},
    );
  }

  Future<List<Map<String, dynamic>>> getTopics() async {
    final res = await _dio.get('/api/topics');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getKolUsers() async {
    final res = await _dio.get('/api/kol');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  // ===== Group Buys =====
  Future<List<Map<String, dynamic>>> getGroupBuys() async {
    final res = await _dio.get('/api/group_buys');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> joinGroupBuy(int groupBuyId, String token) async {
    await _dio.post('/api/group_buys',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'group_buy_id': groupBuyId, 'action': 'join'},
    );
  }

  // ===== Reviews =====
  Future<List<Map<String, dynamic>>> getReviews(int productId) async {
    final res = await _dio.get('/api/reviews', queryParameters: {'product_id': productId});
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addReview(String token, int productId, int rating, String content, {List<String> images = const []}) async {
    await _dio.post('/api/reviews',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'product_id': productId, 'rating': rating, 'content': content, 'images': images},
    );
  }

  // ===== Favorites =====
  Future<List<Map<String, dynamic>>> getFavorites(String token) async {
    final res = await _dio.get('/api/favorites', options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> toggleFavorite(String token, int productId, bool add) async {
    await _dio.post('/api/favorites',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'product_id': productId, 'action': add ? 'add' : 'remove'},
    );
  }

  // ===== Seckill =====
  Future<List<Map<String, dynamic>>> getSeckillEvents() async {
    final res = await _dio.get('/api/seckill');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  // ===== Coupons =====
  Future<List<Map<String, dynamic>>> getCoupons() async {
    final res = await _dio.get('/api/coupons');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMyCoupons(String token) async {
    final res = await _dio.get('/api/coupons/my', options: Options(headers: {'Authorization': 'Bearer $token'}));
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> claimCoupon(String token, int couponId) async {
    await _dio.post('/api/coupons',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {'coupon_id': couponId, 'action': 'claim'},
    );
  }

  // ===== Live =====
  Future<List<Map<String, dynamic>>> getLiveRooms() async {
    final res = await _dio.get('/api/live');
    final data = res.data is List ? res.data as List : (res.data['data'] as List? ?? []);
    return List<Map<String, dynamic>>.from(data);
  }
}

class ChatMessageDTO {
  final int id;
  final String content;
  final String senderType;
  ChatMessageDTO({required this.id, required this.content, required this.senderType});
}
