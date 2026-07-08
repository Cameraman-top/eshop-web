import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  int? _watchingRoom;
  String? _hostingRoom;
  final _chatController = TextEditingController();
  final _chatScroll = ScrollController();
  List<Map<String, dynamic>> _chatMsgs = [];
  html.VideoElement? _videoEl;

  static const HLS_URL = 'http://live.cameraman.top/live/eshop.m3u8';
  static const OBS_SERVER = 'rtmp://233010.push.tlivecloud.com/live/';
  static const OBS_KEY = 'eshop?txSecret=7f6dc779dfbe75b8b62f6a1d2026ad2c&txTime=6A47A762';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _videoEl?.remove();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try { _rooms = await ApiClient().getLiveRooms(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _startHost() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    try {
      final res = await ApiClient().dio.post('/api/rtc/start', data: {'title': '直播中'});
      final rid = res.data['room_id'];
      setState(() { _hostingRoom = rid; _rooms.insert(0, {'id': rid, 'title': '我的直播', 'status': 'online'}); });
      _pollChat(rid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('开播失败: $e')));
    }
  }

  Future<void> _stopHost() async {
    if (_hostingRoom == null) return;
    await ApiClient().dio.post('/api/rtc/stop', data: {'room_id': _hostingRoom});
    setState(() { _hostingRoom = null; });
    _load();
  }

  void _watchRoom(int roomId) {
    setState(() { _watchingRoom = roomId; _chatMsgs = []; });
    _initVideo();
    _pollChat(roomId);
  }

  void _stopWatch() {
    _videoEl?.pause();
    _videoEl?.removeAttribute('src');
    setState(() { _watchingRoom = null; });
  }

  void _initVideo() {
    _videoEl?.remove();
    _videoEl = html.VideoElement()
      ..src = HLS_URL
      ..autoplay = true
      ..controls = false
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '45%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = '#000'
      ..style.zIndex = '999';
    html.document.body?.append(_videoEl!);
  }

  Future<void> _pollChat(int roomId) async {
    while (_watchingRoom == roomId || _hostingRoom == roomId) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/chat', queryParameters: {'room_id': roomId});
        final msgs = (res.data as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _chatMsgs = msgs);
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void _sendChat(int roomId) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    ApiClient().dio.post('/api/rtc/chat', data: {'room_id': roomId, 'user': '我', 'text': text});
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Watching mode
    if (_watchingRoom != null) return _buildWatchView();

    return Scaffold(
      appBar: AppBar(title: const Text('直播'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: _hostingRoom != null
        ? FloatingActionButton.extended(
            onPressed: _stopHost, backgroundColor: Colors.grey, foregroundColor: Colors.white,
            icon: const Icon(Icons.stop), label: const Text('结束直播'),
          )
        : FloatingActionButton.extended(
            onPressed: _startHost, backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white,
            icon: const Icon(Icons.videocam), label: const Text('开播'),
          ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _buildRoomList(),
    );
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.live_tv_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('暂无直播', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('点击右下角开播', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }

    return Column(children: [
      // Host info card
      if (_hostingRoom != null)
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFF4D4F).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF4D4F).withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.circle, size: 8, color: Color(0xFFFF4D4F)), SizedBox(width: 6), Text('直播中', style: TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.w600))]),
            const SizedBox(height: 8),
            Text('OBS 服务器: $OBS_SERVER', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            Text('串流密钥: $OBS_KEY', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 4),
            Text('请用 OBS 推流', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
      // Room grid
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.75),
        itemCount: _rooms.length,
        itemBuilder: (context, i) {
          final r = _rooms[i];
          return GestureDetector(
            onTap: () => _watchRoom(r['id']),
            child: Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Stack(children: [
                Container(color: Colors.grey[300], child: Center(child: Icon(Icons.videocam, size: 40, color: Colors.grey[400]))),
                Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Row(children: [
                  Icon(Icons.circle, size: 6, color: Colors.white), SizedBox(width: 4), Text('直播中', style: TextStyle(color: Colors.white, fontSize: 10)),
                ]))),
              ])),
              Padding(padding: const EdgeInsets.all(10), child: Text(r['title'] ?? '直播', style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
          );
        },
      )),
    ]);
  }

  Widget _buildWatchView() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _stopWatch),
        title: const Text('直播间'),
      ),
      body: Column(children: [
        // Video area (native HTML video element overlaid on top)
        Container(
          height: MediaQuery.of(context).size.height * 0.45,
          color: Colors.black,
          child: const Center(child: Text('等待推流...', style: TextStyle(color: Colors.white54))),
        ),
        // Chat
        Expanded(child: Column(children: [
          Expanded(child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.all(12),
            itemCount: _chatMsgs.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: '${_chatMsgs[i]['user']}: ', style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.w600, fontSize: 13)),
                TextSpan(text: _chatMsgs[i]['text'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ])),
            ),
          )),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[100], border: Border(top: BorderSide(color: Colors.grey[300]!))),
            child: Row(children: [
              Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: '说点什么...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)), style: const TextStyle(fontSize: 14))),
              TextButton(onPressed: () => _sendChat(_watchingRoom!), child: const Text('发送', style: TextStyle(color: Color(0xFFFF4D4F)))),
            ]),
          ),
        ])),
      ]),
    );
  }
}
