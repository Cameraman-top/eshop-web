# eShop 社交商城 - 开发日志

## 项目概述
Flutter 跨平台社交电商，Flutter 3.16.9 + Provider + Python/SQLite 后端。

## 技术栈
- **前端**: Flutter 3.16.9 (HTML 渲染器), Provider 状态管理
- **后端**: Python 3.9 + SQLite, 零依赖 HTTP Server
- **运行**: `localhost:9999` (前端), `localhost:8081` (API), `localhost:8080` (客服后台)

## 目录结构
```
eshop_flutter/
├── lib/
│   ├── main.dart                    # 入口, 5 Tab 导航
│   ├── config/theme.dart            # Material 3 主题
│   ├── models/                      # Product, Category, CartItem
│   ├── services/
│   │   ├── api_client.dart          # Dio 封装, 全部 API 方法
│   │   └── mock_data.dart           # Mock 数据(备用)
│   ├── providers/                   # Cart, Product, User
│   ├── pages/
│   │   ├── home/                    # 首页 Banner+分类+热销
│   │   ├── product_detail/          # 商品详情+评价+立即购买
│   │   ├── cart/                    # 购物车
│   │   ├── order/                   # 订单列表(Tab)
│   │   ├── profile/                 # 我的(登录/订单/客服)
│   │   ├── login/                   # 登录/注册
│   │   ├── chat/                    # 客服聊天
│   │   ├── social/                  # 种草社区(帖子+达人+圈子)
│   │   └── group_buy/               # 拼团
│   └── widgets/                     # ProductCard, GlassCard
└── build/web/                       # 编译产物

eshop_api/
├── api.py                           # 完整 API (572行, 25+ 接口)
├── admin/chat.html                  # 客服后台
└── eshop.db                         # SQLite 数据库
```

## 功能清单

### 基础电商 (已完成)
- [x] 商品浏览 (首页/分类/详情)
- [x] 购物车 (增减/删除/结算)
- [x] 立即购买
- [x] 订单管理 (创建/列表/状态)
- [x] 登录/注册 (手机号+密码, JWT Token)

### 客服系统 (已完成)
- [x] 用户端聊天 (Flutter)
- [x] 客服后台 (HTML, 局域网访问)
- [x] 实时消息收发

### 第一层: 基础社交 (已完成)
- [x] 商品评价 (星级+图文)
- [x] 收藏/心愿单
- [x] 用户主页 (粉丝/关注/帖子数)

### 第二层: 裂变增长 (后端完成, 前端待补)
- [x] 拼团 (创建/参与/进度)
- [x] 优惠券 (后端API)
- [x] 秒杀 (后端API)
- [x] 分销码 (后端API)

### 第三层: 社区生态 (后端完成, 前端待补)
- [x] 种草社区 (帖子流/发布/点赞/圈子)
- [x] 达人榜 (后端API)
- [x] 直播 (后端API)
- [x] 话题圈子 (6个预设话题)

## 数据库表 (17张)
users, products, orders, order_items, chat_sessions, chat_messages,
reviews, favorites, follows, group_buys, group_buy_participants,
coupons, user_coupons, seckill_events, referral_codes,
posts, post_likes, comments, topics, live_rooms

## 启动方式
```bash
# 后端 API
cd ~/projects/eshop_api && python3 api.py

# 前端 (编译后)
cd ~/projects/eshop_flutter/build/web && python3 -m http.server 9999

# 客服后台
cd ~/projects/eshop_api && python3 -m http.server 8080 --bind 0.0.0.0
```

## 已知问题
- macOS 12.7.6 + 4GB 内存, 编译约 2-3 分钟
- HTML 渲染器模式 (避免 CanvasKit 白屏)
- 仅 Web 端可用 (无 Xcode/Android SDK)
- 小程序不支持 (Flutter 生态限制)

## 更新记录
- 2026-07-02: 初始搭建, 7页电商 + 客服
- 2026-07-02: 三层社交商城后端 API 完成
- 2026-07-02: 种草社区 + 拼团前端页面
- 2026-07-02: 5 Tab 导航 (首页/种草/拼团/购物车/我的)
