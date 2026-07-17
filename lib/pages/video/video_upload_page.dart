import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html;
import '../../providers/user_provider.dart';
import '../../services/api_client.dart';

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({super.key});
  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _uploading = false;
  String? _previewUrl;
  html.File? _selectedFile;
  bool _useUrl = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _pickFile() {
    final input = html.FileUploadInputElement()..accept = 'video/*';
    input.click();
    input.onChange.listen((e) {
      final files = input.files;
      if (files?.isEmpty ?? true) return;
      setState(() {
        _selectedFile = files![0];
        _previewUrl = html.Url.createObjectUrl(_selectedFile!);
        _useUrl = false;
      });
    });
  }

  void _clearFile() {
    if (_previewUrl != null) html.Url.revokeObjectUrl(_previewUrl!);
    setState(() {
      _selectedFile = null;
      _previewUrl = null;
      _useUrl = true;
    });
  }

  Future<void> _upload() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }

    final user = context.read<UserProvider>();
    if (!user.isLoggedIn) {
      final result = await Navigator.pushNamed(context, '/login');
      if (result != true || !user.isLoggedIn) return;
    }

    setState(() => _uploading = true);

    try {
      final dio = ApiClient().dio;
      if (_useUrl) {
        final url = _urlCtrl.text.trim();
        if (url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入视频链接')));
          setState(() => _uploading = false);
          return;
        }
        await dio.post('/api/posts', data: {
          'title': title,
          'content': _descCtrl.text.trim(),
          'media_type': 'video',
          'video_url': url,
          'images': '[]',
          'action': 'create',
        }, options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      } else if (_selectedFile != null) {
        // Read file as bytes
        final reader = html.FileReader();
        reader.readAsArrayBuffer(_selectedFile!);
        await reader.onLoad.first;
        final bytes = reader.result as List<int>;
        final formData = FormData.fromMap({
          'title': title,
          'content': _descCtrl.text.trim(),
          'media_type': 'video',
          'video': MultipartFile.fromBytes(bytes, filename: _selectedFile!.name),
        });
        await dio.post('/api/posts', data: formData, options: Options(headers: {'Authorization': 'Bearer ${user.token}'}));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发布短视频'), actions: [
        TextButton(
          onPressed: _uploading ? null : _upload,
          child: _uploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Video source
          const Text('视频来源', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            _sourceTab('视频链接', _useUrl, () => setState(() => _useUrl = true)),
            const SizedBox(width: 8),
            _sourceTab('本地上传', !_useUrl, () => setState(() => _useUrl = false)),
          ]),
          const SizedBox(height: 16),

          if (_useUrl) ...[
            // URL input
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                hintText: '输入视频链接 (https://...)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _urlCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _urlCtrl.clear(); setState(() {}); }) : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_urlCtrl.text.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 12), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(height: 200, width: double.infinity, color: Colors.black, child: const Center(child: Icon(Icons.link, color: Colors.white54, size: 40))))),
          ] else ...[
            // File picker
            if (_previewUrl != null) ...[
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(height: 250, width: double.infinity, color: Colors.black)),
                Positioned(right: 8, top: 8, child: GestureDetector(onTap: _clearFile, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)))),
              ]),
              const SizedBox(height: 8),
              Text(_selectedFile!.name, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text('${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ] else
              GestureDetector(
                onTap: _pickFile,
                child: Container(height: 180, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, width: 1.5, strokeAlign: BorderSide.strokeAlignInside), borderRadius: BorderRadius.circular(10), color: Colors.grey[50]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('点击选择视频文件', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  Text('支持 MP4/MOV，最大 100MB', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ])),
              ),
          ],

          const SizedBox(height: 24),

          // Title
          const Text('标题', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: '给视频起个吸引人的标题',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),

          // Description
          const Text('描述', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '简单描述视频内容...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sourceTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: active ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}
