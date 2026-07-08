# eShop Flutter 商城

跨平台电商 App，基于 Flutter 3.16.9 + Provider 状态管理。

## 运行

```bash
# Web 版（当前可用）
cd ~/projects/eshop_flutter
flutter run -d web-server --web-renderer html --web-port=9999
# 打开 http://localhost:9999

# iOS 版（需要 Xcode）
flutter run -d ios

# macOS 版（需要 Xcode）
flutter run -d macos

# Android 版（需要 Android SDK）
flutter run -d android
```

## 项目结构

```
lib/
├── main.dart                    # 入口 + 路由 + 底部导航
├── config/
│   └── theme.dart               # Material 3 主题
├── models/
│   ├── product.dart             # 商品模型
│   ├── category.dart            # 分类模型
│   └── cart_item.dart           # 购物车模型
├── services/
│   ├── mock_data.dart           # Mock 数据（8商品 + 8分类）
│   └── api_client.dart          # 后端 API 对接（Dio）
├── providers/
│   ├── cart_provider.dart       # 购物车状态管理
│   └── product_provider.dart    # 商品状态管理
├── pages/
│   ├── home/                    # 首页（Banner + 分类 + 热销）
│   ├── category/                # 分类（左栏分类 + 右栏商品）
│   ├── cart/                    # 购物车（增减 + 滑动删除）
│   ├── product_detail/          # 商品详情（规格选择 + 加购）
│   ├── order/                   # 订单（5个Tab）
│   ├── profile/                 # 我的（订单 + 菜单）
│   └── chat/                    # 客服（智能回复）
└── widgets/
    ├── product_card.dart        # 商品卡片
    └── skeleton_loader.dart     # 骨架屏
```

## 页面功能

| 页面 | 功能 |
|------|------|
| 首页 | Banner轮播 + 8分类 + 热销商品网格 |
| 分类 | 左侧分类栏 + 右侧商品列表 |
| 购物车 | 增减数量 + 滑动删除 + 合计结算 |
| 商品详情 | 图片轮播 + 规格选择 + 加入购物车 |
| 订单 | 全部/待付款/待发货/待收货/待评价 |
| 我的 | 订单入口 + 收藏/地址/优惠券/客服/设置 |
| 客服 | 聊天界面 + 关键词自动回复 |

## 后端 API（PHP）

后端代码在 `~/projects/eshop_api/`，接口：

```
GET  /api/products         # 商品列表
GET  /api/products/hot     # 热销
GET  /api/products/{id}    # 详情
GET  /api/categories       # 分类
GET/POST/PUT/DELETE /api/cart    # 购物车
GET/POST /api/orders       # 订单
POST /api/user/register    # 注册
POST /api/user/login       # 登录
```

数据库表结构：`eshop_api/sql/schema.sql`

## 注意事项

- **4GB 内存 Mac**：Web 编译约 3-4 分钟，耐心等待
- **Google Fonts**：在国内被墙，使用 HTML 渲染器（`--web-renderer html`）
- **macOS 12.7.6**：Flutter 锁定 3.16.9 版本
- **中国镜像**：已配置 pub.flutter-io.cn 和 storage.flutter-io.cn
- **审批已关闭**：`approvals.mode: off`，所有命令直接执行
