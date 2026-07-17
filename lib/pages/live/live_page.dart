import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html;
import 'dart:js_util' as jsu;
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
  bool _hosting = false;
  bool _watching = false;
  int? _currentRoom;
  String? _peer;
  String? _err;
  bool _polling = false;
  dynamic _stream;
  dynamic _pc;

  final _chatCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  List<Map<String, dynamic>> _chatMsgs = [];
  int _viewers = 0;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _teardown(); _chatCtrl.dispose(); _chatScroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    try { _rooms = await ApiClient().getLiveRooms(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _teardown() {
    _polling = false;
    try { jsu.callMethod(_pc, 'close', []); } catch (_) {}
    _pc = null;
    if (_stream != null) { try { jsu.callMethod(_stream, 'getTracks', []).forEach((t) => jsu.callMethod(t, 'stop', [])); } catch (_) {} _stream = null; }
    _removeVideoById('live-local');
    _removeVideoById('live-remote');
    if (_currentRoom != null && _hosting) { try { ApiClient().dio.post('/api/rtc/stop', data: {'room_id': _currentRoom}); } catch (_) {} }
  }

  void _removeVideoById(String id) {
    final el = html.document.getElementById(id);
    if (el != null) el.remove();
  }

  html.VideoElement _attachVideo(String id) {
    _removeVideoById(id);
    final v = html.VideoElement()
      ..id = id
      ..autoplay = true
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.objectFit = 'cover'
      ..style.zIndex = '9990'
      ..style.backgroundColor = 'black';
    html.document.body?.append(v);
    return v;
  }

  Future<void> _startHost() async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    setState(() { _err = null; });
    try {
      final media = jsu.getProperty(html.window.navigator.mediaDevices!, 'getUserMedia');
      _stream = await jsu.promiseToFuture(jsu.callMethod(media, 'call', [html.window.navigator.mediaDevices!, jsu.jsify({'video': true, 'audio': true})]));
      final v = _attachVideo('live-local')..srcObject = _stream..muted = true;
      final res = await ApiClient().dio.post('/api/rtc/start', data: {'title': '我的直播'}, options: _auth(user.token!));
      _currentRoom = (res.data['room_id'] is int) ? res.data['room_id'] : int.tryParse('${res.data['room_id']}');
      if (!mounted) return;
      setState(() { _hosting = true; });
      _polling = true;
      _pollOffers();
      _pollChat();
      _pollViewers();
    } catch (e) {
      if (mounted) setState(() { _err = '开播失败: $e'; });
    }
  }

  Future<void> _watchRoom(int rid) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    setState(() { _err = null; _currentRoom = rid; _watching = true; });
    _attachVideo('live-remote');
    try { await ApiClient().dio.post('/api/rtc/join', data: {'room_id': rid}, options: _auth(user.token!)); } catch (_) {}
    _peer = 'v${DateTime.now().millisecondsSinceEpoch}';
    _pc = _makePc(rid, _peer!, isHost: false, token: user.token!);
    try {
      final offer = await jsu.promiseToFuture(jsu.callMethod(_pc, 'createOffer', [jsu.jsify({'offerToReceiveVideo': true, 'offerToReceiveAudio': true})]));
      await jsu.promiseToFuture(jsu.callMethod(_pc, 'setLocalDescription', [offer]));
      await ApiClient().dio.post('/api/rtc/offer', data: {'room_id': rid, 'peer': _peer, 'sdp': _sdpToObj(offer)});
      _polling = true;
      _pollAnswer();
      _pollChat();
      _pollViewers();
    } catch (e) { if (mounted) setState(() => _err = '进房失败: $e'); }
  }

  dynamic _makePc(int rid, String peer, {required bool isHost, required String token}) {
    final iceServers = jsu.jsify([{'urls': 'stun:stun.l.google.com:19302'}, {'urls': 'stun:stun1.l.google.com:19302'}]);
    final pc = jsu.callConstructor(jsu.getProperty(html.window, 'RTCPeerConnection'), [iceServers]);
    jsu.setProperty(pc, 'onicecandidate', jsu.allowInterop((ev) {
      final c = jsu.getProperty(ev, 'candidate');
      if (c == null) return;
      try { ApiClient().dio.post('/api/rtc/ice', data: {'room_id': rid, 'peer': peer, 'candidate': {'candidate': jsu.getProperty(c, 'candidate'), 'sdpMid': jsu.getProperty(c, 'sdpMid'), 'sdpMLineIndex': jsu.getProperty(c, 'sdpMLineIndex')}}); } catch (_) {}
    }));
    jsu.setProperty(pc, 'ontrack', jsu.allowInterop((ev) {
      final stream = jsu.getProperty(ev, 'stream');
      if (stream != null) {
        final el = html.document.getElementById('live-remote');
        if (el is html.VideoElement) el.srcObject = stream;
      }
    }));
    if (isHost && _stream != null) {
      try {
        final tracks = jsu.callMethod(_stream, 'getTracks', []);
        final senders = jsu.callMethod(pc, 'getSenders', []);
        for (var i = 0; i < tracks.length; i++) {
          try { jsu.callMethod(pc, 'addTrack', [jsu.getProperty(tracks, i), _stream]); } catch (_) {}
        }
      } catch (_) {}
    }
    _pollIce(token, rid, peer, pc);
    return pc;
  }

  void _pollOffers() async {
    while (_polling && _hosting && _currentRoom != null) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/offers', queryParameters: {'room_id': _currentRoom});
        final offers = (res.data is Map) ? res.data as Map : {};
        for (final entry in offers.entries) {
          final viewerPeer = entry.key as String;
          final sdp = entry.value;
          if (sdp == null) continue;
          await _acceptViewer(viewerPeer, sdp);
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _acceptViewer(String vp, dynamic offer) async {
    try {
      final user = context.read<UserProvider>();
      final pc = _makePc(_currentRoom!, vp, isHost: true, token: user.token!);
      await jsu.promiseToFuture(jsu.callMethod(pc, 'setRemoteDescription', [jsu.jsify(offer)]));
      final ans = await jsu.promiseToFuture(jsu.callMethod(pc, 'createAnswer', []));
      await jsu.promiseToFuture(jsu.callMethod(pc, 'setLocalDescription', [ans]));
      await ApiClient().dio.post('/api/rtc/answer', data: {'room_id': _currentRoom, 'peer': vp, 'sdp': _sdpToObj(ans)});
    } catch (_) {}
  }

  void _pollAnswer() async {
    while (_polling && _watching && _currentRoom != null && _pc != null) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/answer', queryParameters: {'room_id': _currentRoom, 'peer': _peer});
        final sdp = res.data?['sdp'];
        if (sdp != null) {
          await jsu.promiseToFuture(jsu.callMethod(_pc, 'setRemoteDescription', [jsu.jsify(sdp)]));
          break;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _pollIce(String token, int rid, String peer, dynamic pc) async {
    while (_polling && _currentRoom == rid && pc != null) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/ices', queryParameters: {'room_id': rid});
        final list = (res.data is List) ? res.data as List : (res.data is Map ? (res.data['data'] as List? ?? []) : []);
        for (final e in list) {
          final m = e as Map;
          if (m['peer'] != peer) continue;
          final c = m['candidate'];
          if (c == null) continue;
          final candMap = c is String ? jsonDecode(c) : c;
          try {
            if (candMap is Map) {
              final rc = jsu.callConstructor(jsu.getProperty(html.window, 'RTCIceCandidate'), [jsu.jsify(candMap)]);
              jsu.callMethod(pc, 'addIceCandidate', [rc]);
            }
          } catch (_) {}
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _pollChat() async {
    while (_polling && _currentRoom != null) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/chat', queryParameters: {'room_id': _currentRoom});
        final data = res.data;
        final list = data is List ? data : (data is Map ? (data['data'] as List? ?? []) : []);
        if (mounted) setState(() => _chatMsgs = List<Map<String, dynamic>>.from(list));
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void _pollViewers() async {
    while (_polling && _currentRoom != null) {
      try {
        final res = await ApiClient().dio.get('/api/rtc/viewers', queryParameters: {'room_id': _currentRoom});
        final cnt = res.data is Map ? (res.data['count'] ?? 0) : 0;
        if (mounted) setState(() => _viewers = (cnt is int) ? cnt : (int.tryParse('$cnt') ?? 0));
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  void _sendChat() {
    final t = _chatCtrl.text.trim();
    if (t.isEmpty || _currentRoom == null) return;
    _chatCtrl.clear();
    final user = context.read<UserProvider>();
    ApiClient().dio.post('/api/rtc/chat', data: {'room_id': _currentRoom, 'user': user.nickname.isEmpty ? '我' : user.nickname, 'text': t});
  }

  void _stopHost() { _teardown(); if (mounted) setState(() { _hosting = false; _currentRoom = null; }); _load(); }
  void _leaveRoom() { _teardown(); if (mounted) setState(() { _watching = false; _currentRoom = null; }); }

  Options _auth(String t) => Options(headers: {'Authorization': 'Bearer $t'});

  Map<String, dynamic> _sdpToObj(dynamic s) {
    if (s is Map) return Map<String, dynamic>.from(s);
    return {'type': 'offer', 'sdp': '$s'};
  }

  @override
  Widget build(BuildContext context) {
    if (_hosting || _watching) return _buildLive();
    return Scaffold(
      appBar: AppBar(title: const Text('直播'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _startHost, backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, icon: const Icon(Icons.videocam), label: const Text('开播')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _rooms.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.live_tv_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无直播', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text('点右下角开播，开启你的直播', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.75),
            itemCount: _rooms.length,
            itemBuilder: (ctx, i) {
              final r = _rooms[i];
              return GestureDetector(
                onTap: () => _watchRoom(r['id'] is int ? r['id'] as int : int.parse('${r['id']}')),
                child: Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Stack(children: [
                    Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.videocam, size: 40, color: Colors.white54))),
                    const Positioned(top: 8, left: 8, child: DecoratedBox(decoration: BoxDecoration(color: Colors.red), child: Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Row(children: [Icon(Icons.circle, size: 6, color: Colors.white), SizedBox(width: 4), Text('直播中', style: TextStyle(color: Colors.white, fontSize: 10))])))),
                  ])),
                  Padding(padding: const EdgeInsets.all(10), child: Text(r['title'] ?? '直播', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ])),
              );
            },
          ),
    );
  }

  Widget _buildLive() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (_err != null) Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_err!, style: const TextStyle(color: Colors.white70)))),
        SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
          Row(children: [const Icon(Icons.circle, size: 8, color: Colors.red), const SizedBox(width: 4), Text(_hosting ? '我正在直播' : '直播中', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]),
          const SizedBox(width: 16),
          Row(children: [const Icon(Icons.visibility, color: Colors.white70, size: 16), const SizedBox(width: 4), Text('$_viewers', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _hosting ? _stopHost : _leaveRoom),
        ]))),
        Positioned(bottom: 0, left: 0, right: 0, child: Column(children: [
          if (_hosting) Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.videocam, color: Colors.white, size: 16), SizedBox(width: 6), Text('摄像头直播中', style: TextStyle(color: Colors.white, fontSize: 12))]),
          ),
          Container(height: 200, padding: const EdgeInsets.all(12), child: ListView.builder(
            controller: _chatScroll,
            itemCount: _chatMsgs.length,
            itemBuilder: (ctx, i) {
              final m = _chatMsgs[i];
              return Padding(padding: const EdgeInsets.only(bottom: 4), child: RichText(text: TextSpan(children: [
                TextSpan(text: '${m['user'] ?? '匿名'}: ', style: const TextStyle(color: Color(0xFFFF7A45), fontSize: 13)),
                TextSpan(text: m['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])));
            },
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            color: Colors.black.withOpacity(0.4),
            child: SafeArea(child: Row(children: [
              Expanded(child: TextField(controller: _chatCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: '发条弹幕...', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), onSubmitted: (_) => _sendChat())),
              const SizedBox(width: 8),
              IconButton(onPressed: _sendChat, icon: const Icon(Icons.send, color: Color(0xFFFF4D4F))),
            ])),
          ),
        ])),
      ]),
    );
  }
}
