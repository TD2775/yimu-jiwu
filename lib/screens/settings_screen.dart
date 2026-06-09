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
  bool _autoBackup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _webdavUrlCtrl.text = await DatabaseService.getSetting('webdav_url') ?? '';
    _webdavUserCtrl.text = await DatabaseService.getSetting('webdav_user') ?? '';
    _webdavPassCtrl.text = await DatabaseService.getSetting('webdav_pass') ?? '';
    final v = await DatabaseService.getSetting('auto_backup');
    if (mounted) setState(() => _autoBackup = v == '1');
    if (_autoBackup) _startAutoBackup();
  }

  void _startAutoBackup() {
    Future.delayed(const Duration(hours: 24), () {
      if (mounted && _autoBackup) {
        _backupNow();
        _startAutoBackup();
      }
    });
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
            SwitchListTile(
              title: const Text('自动定时备份', style: TextStyle(fontSize: 14)),
              subtitle: const Text('开启后每24小时自动备份到 WebDAV', style: TextStyle(fontSize: 12)),
              value: _autoBackup,
              activeColor: AppColors.primary,
              onChanged: (v) { setState(() => _autoBackup = v); DatabaseService.setSetting('auto_backup', v ? '1' : '0'); if (v) _startAutoBackup(); },
            ),
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
            const ListTile(leading: Icon(Icons.info_outline), title: Text('关于一木记物'), subtitle: Text('v1.0.1 · Flutter 复刻版')),
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
      final baseUrl = base.replaceAll(RegExp(r'/$'), '');

      // 123云盘 WebDAV 兼容：直接 PUT 单个备份文件到根目录
      final backupName = 'yimu_backup.json';
      final backupUri = Uri.parse('$baseUrl/$backupName');

      // 第 0 步：删除旧的备份文件（只保留最新一个）
      try {
        final httpClient = HttpClient();
        final delReq = await httpClient.openUrl('DELETE', backupUri);
        delReq.headers.set('Authorization', 'Basic $auth');
        final delResp = await delReq.close();
        await delResp.drain();
        httpClient.close();
      } catch (_) {}

      // 第 1 步：收集所有数据
      final db = await DatabaseService.database;
      await db.close();
      final dbBytes = await File(db.path).readAsBytes();

      // 收集图片
      final provider = context.read<ItemProvider>();
      final images = <Map<String, String>>[];
      for (final item in provider.items) {
        for (final path in item.imagePaths) {
          final file = File(path);
          if (await file.exists()) {
            images.add({
              'path': path,
              'data': base64Encode(await file.readAsBytes()),
            });
          }
        }
      }

      // 打包为 JSON
      final backupJson = jsonEncode({
        'db': base64Encode(dbBytes),
        'images': images,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      });

      // 第 2 步：上传单个备份文件
      final httpClient = HttpClient();
      final putReq = await httpClient.openUrl('PUT', backupUri);
      putReq.headers.set('Authorization', 'Basic $auth');
      putReq.headers.set('Content-Type', 'application/json; charset=utf-8');
      putReq.add(utf8.encode(backupJson));
      final putResp = await putReq.close();
      final statusCode = putResp.statusCode;
      httpClient.close();

      if (statusCode >= 200 && statusCode < 300) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份成功！数据库 + ${images.length} 张图片'), backgroundColor: AppColors.accent));
      } else {
        throw Exception('HTTP $statusCode — 请检查 WebDAV 地址和权限');
      }
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

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('恢复数据'), content: const Text('将从 WebDAV 恢复备份。\n当前数据将被覆盖。确定继续？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定恢复', style: TextStyle(color: AppColors.danger)))],
    ));
    if (ok != true) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在恢复...')));
    try {
      final httpClient = HttpClient();

      // 1. 下载单个备份 JSON 文件
      final getReq = await httpClient.getUrl(Uri.parse('$baseUrl/yimu_backup.json'));
      getReq.headers.set('Authorization', 'Basic $auth');
      final getResp = await getReq.close();
      if (getResp.statusCode >= 400) throw Exception('下载备份失败: HTTP ${getResp.statusCode}');
      final body = await getResp.transform(utf8.decoder).join();
      final backup = jsonDecode(body) as Map<String, dynamic>;

      // 2. 恢复数据库
      final dbBytes = base64Decode(backup['db'] as String);
      final dbPath = (await DatabaseService.database).path;
      final dbDir = dbPath.replaceAll(RegExp(r'[^/\\]+$'), '');
      await DatabaseService.database.then((d) => d.close());
      await File(dbPath).writeAsBytes(dbBytes);

      // 3. 恢复图片
      final images = (backup['images'] as List?) ?? [];
      int imgCount = 0;
      for (final img in images) {
        try {
          final path = img['path'] as String;
          final data = base64Decode(img['data'] as String);
          final file = File(path);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data);
          imgCount++;
        } catch (_) {}
      }

      httpClient.close();

      // 4. 重新加载
      final provider = context.read<ItemProvider>();
      await provider.loadAll();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复完成！数据库 + $imgCount 张图片'), backgroundColor: AppColors.accent));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: $e'), duration: const Duration(seconds: 4), backgroundColor: AppColors.danger));
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
