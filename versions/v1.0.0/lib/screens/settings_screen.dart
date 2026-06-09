import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'category_manage_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _webdavUrlCtrl = TextEditingController();
  final _webdavUserCtrl = TextEditingController();
  final _webdavPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWebDAV();
  }

  Future<void> _loadWebDAV() async {
    _webdavUrlCtrl.text = await DatabaseService.getSetting('webdav_url') ?? '';
    _webdavUserCtrl.text = await DatabaseService.getSetting('webdav_user') ?? '';
    _webdavPassCtrl.text = await DatabaseService.getSetting('webdav_pass') ?? '';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ---- 功能开关 ----
        Card(
          child: Column(children: [
            SwitchListTile(
              title: const Text('库存管理'),
              subtitle: const Text('开启后物品详情显示库存数量及预警'),
              value: provider.showInventory,
              activeColor: AppColors.primary,
              onChanged: (v) => provider.setShowInventory(v),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('借出管理'),
              subtitle: const Text('开启后物品详情可记录借出/归还'),
              value: provider.showLending,
              activeColor: AppColors.primary,
              onChanged: (v) => provider.setShowLending(v),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ---- 数据管理 ----
        Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('分类管理'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManageScreen()))),
          ]),
        ),
        const SizedBox(height: 12),

        // ---- WebDAV 云备份 ----
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.cloud_outlined, color: AppColors.primary), const SizedBox(width: 8), const Text('WebDAV 云备份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            TextField(controller: _webdavUrlCtrl, decoration: const InputDecoration(labelText: 'WebDAV 地址', hintText: 'https://your-server.com/dav/'), keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            TextField(controller: _webdavUserCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 12),
            TextField(controller: _webdavPassCtrl, decoration: const InputDecoration(labelText: '密码'), obscureText: true),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _saveWebDAV, icon: const Icon(Icons.save), label: const Text('保存配置'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: _backupNow, icon: const Icon(Icons.backup), label: const Text('备份'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _restoreNow, icon: const Icon(Icons.restore), label: const Text('恢复'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.info))),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 38, child: OutlinedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_find, size: 16),
              label: const Text('检测连接', style: TextStyle(fontSize: 13)),
            )),
          ])),
        ),
        const SizedBox(height: 12),

        // ---- 关于 ----
        Card(
          child: Column(children: [
            const ListTile(leading: Icon(Icons.info_outline), title: Text('关于一木记物'), subtitle: Text('v1.0.0 · Flutter 复刻版')),
          ]),
        ),
      ]),
    );
  }

  Widget _modeBtn(IconData icon, String label, int mode, ItemProvider p) {
    final sel = p.displayMode == mode;
    return GestureDetector(
      onTap: () => p.setDisplayMode(mode),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: sel ? AppColors.primaryLight : AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(icon, color: sel ? AppColors.primary : AppColors.textSecondary), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: sel ? AppColors.primary : AppColors.textSecondary))])),
    );
  }

  Future<void> _saveWebDAV() async {
    await DatabaseService.setSetting('webdav_url', _webdavUrlCtrl.text.trim());
    await DatabaseService.setSetting('webdav_user', _webdavUserCtrl.text.trim());
    await DatabaseService.setSetting('webdav_pass', _webdavPassCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WebDAV 配置已保存')));
  }

  Future<void> _backupNow() async {
    final base = _webdavUrlCtrl.text.trim();
    if (base.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先配置 WebDAV 地址')));
      return;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在全量备份...')));
    try {
      final auth = base64Encode(utf8.encode('${_webdavUserCtrl.text.trim()}:${_webdavPassCtrl.text.trim()}'));
      final ts = DateTime.now().millisecondsSinceEpoch;
      final baseUrl = base.replaceAll(RegExp(r'/$'), '');

      Future<void> uploadFile(String remotePath, List<int> bytes) async {
        final httpClient = HttpClient();
        // ensure folder exists — try MKCOL
        final parents = remotePath.split('/')..removeLast();
        var folder = baseUrl;
        for (final seg in parents) {
          folder += '/$seg';
          try {
            final mkReq = await httpClient.putUrl(Uri.parse(folder));
            mkReq.headers.set('Authorization', 'Basic $auth');
            mkReq.headers.set('Content-Length', '0');
            final mkResp = await mkReq.close();
            mkResp.drain(); // ignore
          } catch (_) {}
        }

        final uri = Uri.parse('$baseUrl/$remotePath');
        final req = await httpClient.putUrl(uri);
        req.headers.set('Authorization', 'Basic $auth');
        req.headers.set('Content-Type', 'application/octet-stream');
        req.add(bytes);
        final resp = await req.close();
        if (resp.statusCode >= 400) throw Exception('HTTP ${resp.statusCode}');
        httpClient.close();
      }

      // 1. Upload database
      final db = await DatabaseService.database;
      await db.close(); // flush
      final dbPath = db.path;
      final dbBytes = await File(dbPath).readAsBytes();
      await uploadFile('yimu_backup_$ts/database.db', dbBytes);

      // 2. Upload all images from all items
      final provider = context.read<ItemProvider>();
      int imgCount = 0;
      for (final item in provider.items) {
        for (final path in item.imagePaths) {
          final file = File(path);
          if (await file.exists()) {
            final name = path.replaceAll(RegExp(r'[/\\:]'), '_');
            await uploadFile('yimu_backup_$ts/images/$name', await file.readAsBytes());
            imgCount++;
          }
        }
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份完成！数据库 + $imgCount 张图片')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e'), duration: const Duration(seconds: 3)));
    }
  }

  Future<void> _restoreNow() async {
    final base = _webdavUrlCtrl.text.trim();
    if (base.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先配置 WebDAV 地址')));
      return;
    }
    final baseUrl = base.replaceAll(RegExp(r'/$'), '');
    final auth = base64Encode(utf8.encode('${_webdavUserCtrl.text.trim()}:${_webdavPassCtrl.text.trim()}'));

    // Confirm
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('恢复数据'), content: const Text('将从 WebDAV 恢复最新的备份到本地。\n当前数据将被覆盖。确定继续？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定恢复', style: TextStyle(color: AppColors.danger)))],
    ));
    if (ok != true) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在恢复...')));
    try {
      // 1. List backup folders via PROPFIND (depth 1)
      final httpClient = HttpClient();
      final listReq = await httpClient.openUrl('PROPFIND', Uri.parse(baseUrl));
      listReq.headers.set('Authorization', 'Basic $auth');
      listReq.headers.set('Depth', '1');
      final listResp = await listReq.close();
      if (listResp.statusCode >= 400) throw Exception('无法列出目录: HTTP ${listResp.statusCode}');
      final body = await listResp.transform(utf8.decoder).join();

      // Extract folder names matching yimu_backup_*
      final folders = <String>[];
      final regex = RegExp(r'href>([^<]*yimu_backup_\d+)</href>');
      for (final m in regex.allMatches(body)) {
        final u = m.group(1)!.trim();
        final name = u.endsWith('/') ? u.substring(0, u.length - 1) : u;
        folders.add(name.split('/').last);
      }
      if (folders.isEmpty) throw Exception('未找到备份文件夹');

      // Pick latest by timestamp
      folders.sort((a, b) => b.compareTo(a));
      final latest = folders.first;
      final backupPath = '$baseUrl/$latest';

      // 2. Download database
      final dbBytes = await _downloadFile(httpClient, '$backupPath/database.db', auth);
      final dbDir = (await DatabaseService.database).path.replaceAll(RegExp(r'[^/\\]+$'), '');
      final dbFile = File('${dbDir}yimu_restore.db');
      await dbFile.writeAsBytes(dbBytes);

      // 3. Download images
      final imgListReq = await httpClient.openUrl('PROPFIND', Uri.parse('$backupPath/images'));
      imgListReq.headers.set('Authorization', 'Basic $auth');
      imgListReq.headers.set('Depth', '1');
      final imgListResp = await imgListReq.close();
      final imgBody = await imgListResp.transform(utf8.decoder).join();
      final imgRegex = RegExp(r'href>([^<]+images/[^<]+)</href>');
      final imgPaths = <String>{};
      for (final m in imgRegex.allMatches(imgBody)) {
        final p = m.group(1)!.trim();
        if (!p.endsWith('/')) imgPaths.add(p);
      }

      final tmpDir = await Directory.systemTemp.createTemp('yimu_restore_');
      int imgCount = 0;
      for (final imgRel in imgPaths) {
        try {
          final bytes = await _downloadFile(httpClient, '$baseUrl/$imgRel', auth);
          final local = File('${tmpDir.path}/${imgRel.split('/').last}');
          await local.writeAsBytes(bytes);
          imgCount++;
        } catch (_) {}
      }

      // 4. Swap database and reload
      await DatabaseService.database.then((d) => d.close());
      final targetDb = File(dbDir + 'yimu_jiwu.db');
      await dbFile.copy(targetDb.path);
      await dbFile.delete();

      final provider = context.read<ItemProvider>();
      await provider.loadAll();
      httpClient.close();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复完成！数据库 + $imgCount 张图片。图片已保存到: ${tmpDir.path}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e'), duration: const Duration(seconds: 4)));
    }
  }

  Future<List<int>> _downloadFile(HttpClient httpClient, String url, String auth) async {
    final req = await httpClient.getUrl(Uri.parse(url));
    req.headers.set('Authorization', 'Basic $auth');
    final resp = await req.close();
    if (resp.statusCode >= 400) throw Exception('下载 $url 失败: HTTP ${resp.statusCode}');
    return await resp.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));
  }

  Future<void> _testConnection() async {
    final base = _webdavUrlCtrl.text.trim();
    if (base.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 WebDAV 地址')));
      return;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在检测连接...')));
    try {
      final auth = base64Encode(utf8.encode('${_webdavUserCtrl.text.trim()}:${_webdavPassCtrl.text.trim()}'));
      final httpClient = HttpClient();
      final req = await httpClient.openUrl('PROPFIND', Uri.parse(base.replaceAll(RegExp(r'/$'), '') + '/'));
      req.headers.set('Authorization', 'Basic $auth');
      req.headers.set('Depth', '0');
      final resp = await req.close();
      httpClient.close();
      if (resp.statusCode < 400) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 连接成功！WebDAV 服务器可用'), backgroundColor: AppColors.accent));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 连接失败: HTTP ${resp.statusCode}'), backgroundColor: AppColors.danger));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 无法连接: $e'), backgroundColor: AppColors.danger, duration: const Duration(seconds: 3)));
    }
  }
}
