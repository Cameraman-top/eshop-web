import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';
import '../profile/user_profile_page.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});
  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _kolUsers = [];
  int _selectedTopic = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiClient();
      _posts = await api.getPosts(topicId: _selectedTopic > 0 ? _selectedTopic : null);
      _topics = await api.getTopics();
      _kolUsers = await api.getKolUsers();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('种草社区'),
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () => _createPost(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF4D4F),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: '推荐'), Tab(text: '达人'), Tab(text: '圈子')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(),
          _buildKolList(),
          _buildTopicList(),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 12), Text('还没有帖子', style: TextStyle(color: Colors.grey[400]))]));
    return Column(
      children: [
        // Topic filter
        SizedBox(
          height: 44,
          child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), itemCount: _topics.length + 1, itemBuilder: (context, i) {
            final selected = i == 0 ? _selectedTopic == 0 : _selectedTopic == _topics[i-1]['id'];
            final label = i == 0 ? '全部' : (_topics[i-1]['name'] ?? '');
            return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12)),
              selected: selected,
              selectedColor: const Color(0xFFFF4D4F),
              backgroundColor: Colors.grey[100],
              onSelected: (_) { setState(() { _selectedTopic = i == 0 ? 0 : _topics[i-1]['id']; _loading = true; }); _loadData(); },
            ));
          }),
        ),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _posts.length, itemBuilder: (context, i) => _buildPostCard(_posts[i])),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () {
            final uid = post['user_id'];
            if (uid != null) Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: uid is int ? uid : int.parse('$uid'))));
          },
          child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.grey[200], child: Text((post['nickname'] ?? '?')[0], style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post['nickname'] ?? '匿名', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(post['created_at'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
          ]),
        ),
        if ((post['title'] ?? '').isNotEmpty) ...[const SizedBox(height: 10), Text(post['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))],
        const SizedBox(height: 8),
        Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          _actionChip(Icons.favorite_border, '${post['like_count'] ?? 0}', () => _toggleLike(post)),
          const SizedBox(width: 16),
          _actionChip(Icons.chat_bubble_outline, '${post['comment_count'] ?? 0}', () {}),
          const Spacer(),
          _actionChip(Icons.share_outlined, '分享', () {}),
        ]),
      ])),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey[500]),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
    ]));
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    try {
      final api = ApiClient();
      final isLiked = post['is_liked'] == true;
      await api.toggleLike(post['id'], user.token!, !isLiked);
      setState(() {
        post['is_liked'] = !isLiked;
        post['like_count'] = (post['like_count'] ?? 0) + (isLiked ? -1 : 1);
      });
    } catch (_) {}
  }

  void _createPost(BuildContext context) async {
    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) { Navigator.pushNamed(context, '/login'); return; }
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int selectedTid = _selectedTopic;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('发布帖子', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleController, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: contentController, maxLines: 4, decoration: const InputDecoration(labelText: '说点什么...', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: _topics.map((t) => FilterChip(
            label: Text(t['name'] ?? '', style: TextStyle(fontSize: 12, color: selectedTid == t['id'] ? Colors.white : Colors.black87)),
            selected: selectedTid == t['id'],
            selectedColor: const Color(0xFFFF4D4F),
            onSelected: (_) => setModalState(() => selectedTid = t['id']),
          )).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (contentController.text.trim().isEmpty) return;
              try {
                await ApiClient().createPost(user.token!, contentController.text.trim(), title: titleController.text.trim(), topicId: selectedTid);
                Navigator.pop(ctx);
                _loadData();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e'))); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('发布'),
          )),
          const SizedBox(height: 20),
        ]),
      )),
    );
    titleController.dispose();
    contentController.dispose();
  }

  Widget _buildKolList() {
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _kolUsers.length, itemBuilder: (context, i) {
      final u = _kolUsers[i];
      return Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text((u['nickname'] ?? '?')[0])),
          title: Text(u['nickname'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(u['bio'] ?? ''),
          trailing: OutlinedButton(onPressed: () {}, child: Text('关注', style: TextStyle(fontSize: 12))),
        ),
      );
    });
  }

  Widget _buildTopicList() {
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _topics.length, itemBuilder: (context, i) {
      final t = _topics[i];
      return Card(
        child: ListTile(
          leading: Text(t['icon'] ?? '📌', style: const TextStyle(fontSize: 28)),
          title: Text(t['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(t['description'] ?? ''),
          trailing: Text('${t['post_count'] ?? 0} 帖', style: TextStyle(color: Colors.grey[500])),
          onTap: () { setState(() { _selectedTopic = t['id']; }); _tabController.animateTo(0); _loadData(); },
        ),
      );
    });
  }
}
