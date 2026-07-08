import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_client.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ApiClient _api = ApiClient();
  int? _sessionId;
  Timer? _pollTimer;
  bool _useApi = true;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: '您好！我是eShop客服小e，有什么可以帮您的吗？\n\n您可以问我：\n• 订单查询\n• 退换货政策\n• 商品咨询\n• 物流信息\n• 回复"转人工"连接人工客服',
      isUser: false,
    ));
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_sessionId != null && _useApi) _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    try {
      final msgs = await _api.getChatMessages(_sessionId!);
      if (!mounted) return;
      setState(() {
        final existingIds = _messages.where((m) => m.id != null).map((m) => m.id).toSet();
        for (final m in msgs) {
          if (!existingIds.contains(m.id)) {
            _messages.add(ChatMessage(
              id: m.id,
              text: m.content,
              isUser: m.senderType == 'user',
            ));
          }
        }
      });
      _scrollToBottom();
    } catch (_) {
      _useApi = false;
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
    });
    _scrollToBottom();

    if (_useApi) {
      try {
        // 先添加到本地（临时 id=-1 占位）
        final tempMsg = _messages.last;
        final result = await _api.sendChatMessage(
          sessionId: _sessionId,
          content: text,
          senderType: 'user',
          userName: '用户',
        );
        if (_sessionId == null) {
          _sessionId = result['session_id'];
        }
        // 更新本地消息 id，避免轮询重复
        tempMsg.id = result['id'];
        await _loadMessages();
        return;
      } catch (_) {
        _useApi = false;
      }
    }

    // Mock fallback
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: _getAutoReply(text),
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  String _getAutoReply(String msg) {
    if (msg.contains('订单') || msg.contains('物流')) {
      return '您的订单我们已收到，正在加急处理中。\n一般发货后1-3天送达，请耐心等待哦~';
    } else if (msg.contains('退货') || msg.contains('换货') || msg.contains('退款')) {
      return '我们支持7天无理由退换货。\n请确保商品完好，包装齐全。\n在"我的订单"中可直接申请退换货。';
    } else if (msg.contains('优惠') || msg.contains('折扣') || msg.contains('活动')) {
      return '现在正在进行满299减50的活动！\n新用户首单还有额外9折优惠哦~';
    } else if (msg.contains('转人工')) {
      return '正在为您转接人工客服，请稍候...\n（提示：当前为演示模式，客服后台地址：eshop_api/admin/chat.html）';
    } else if (msg.contains('你好') || msg.contains('嗨') || msg.contains('hi')) {
      return '您好！很高兴为您服务，请问有什么需要帮助的吗？';
    } else {
      return '收到您的消息了！\n让我为您查询一下，请稍等片刻~\n（如需人工服务，请回复"转人工"）';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Text('小e', style: TextStyle(fontSize: 12, color: Colors.blue))),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('客服小e', style: TextStyle(fontSize: 16)),
            Text('在线', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.green)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildBubble(_messages[index]),
          ),
        ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFFFF4D4F) : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Text(msg.text, style: TextStyle(fontSize: 14, color: msg.isUser ? Colors.white : Colors.black87, height: 1.5)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -1))]),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入您的问题...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0xFFFF4D4F), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

class ChatMessage {
  int? id;
  final String text;
  final bool isUser;
  ChatMessage({this.id, required this.text, required this.isUser});
}
