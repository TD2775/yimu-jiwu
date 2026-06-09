import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class WebSearchScreen extends StatefulWidget {
  final String searchQuery;
  const WebSearchScreen({super.key, required this.searchQuery});

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgPrimary)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { setState(() => _loading = false); Future.delayed(const Duration(milliseconds: 1500), _injectJS); },
        onWebResourceError: (e) => setState(() => _loading = false),
      ))
      ..addJavaScriptChannel('ImgClick', onMessageReceived: (msg) {
        final url = msg.message;
        if (url.isNotEmpty && url.startsWith('http')) _showPreview(url);
      });

    final query = Uri.encodeComponent(widget.searchQuery.isNotEmpty ? widget.searchQuery : '物品');
    _controller.loadRequest(Uri.parse('https://image.baidu.com/search/index?tn=baiduimage&word=$query'));
  }

  Future<void> _injectJS() async {
    await _controller.runJavaScript('''
(function(){
  var imgs=document.querySelectorAll('img');
  imgs.forEach(function(img){
    if(img.naturalWidth>80&&img.src&&img.src.startsWith('http')){
      img.style.border='2px solid transparent';
      img.addEventListener('click',function(e){e.preventDefault();e.stopPropagation();ImgClick.postMessage(img.src);});
    }
  });
})();
''');
  }

  void _showPreview(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16), const Text('设为封面？', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, height: 220, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(height: 120, color: AppColors.bgSecondary, child: const Center(child: Text('加载失败'))))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: () => _download(url, ctx),
          icon: const Icon(Icons.check_circle), label: const Text('确认为封面', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      ]))),
    );
  }

  Future<void> _download(String url, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse(url), headers: {
        'Referer': 'https://image.baidu.com/',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      });
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final dir = await getTemporaryDirectory();
      final ext = url.contains('.png') ? '.png' : '.jpg';
      final file = File('${dir.path}/cover_${DateTime.now().millisecondsSinceEpoch}$ext');
      await file.writeAsBytes(resp.bodyBytes);
      setState(() => _loading = false);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载失败，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索图片: ${widget.searchQuery}', style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: '刷新', onPressed: () { _injectJS(); _controller.reload(); }),
        ],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const LinearProgressIndicator(),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withAlpha(230), border: const Border(top: BorderSide(color: AppColors.divider))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.touch_app, size: 15, color: AppColors.primary),
            SizedBox(width: 6),
            Text('点 击 图 片 即 可 设 为 封 面', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ]),
        )),
      ]),
    );
  }
}
