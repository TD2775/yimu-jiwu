import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'web_search_screen.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item;
  const AddEditItemScreen({super.key, this.item});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _uuid = const Uuid();

  // 内置渠道
  final _builtinChannels = ['淘宝', '拼多多', '京东', '闲鱼', '抖音', '快手', '天猫', '得物', '1688', '实体店'];
  final _builtinMethods = ['全款', '分期', '合租'];

  // 模板
  int _selectedTemplate = 0;

  // 基本信息
  String _name = '';
  double? _price;
  double? _extraCost;
  String? _extraCostNote;
  DateTime? _purchaseDate = DateTime.now();
  String? _categoryId;
  String? _subCategoryId;
  String? _coverImagePath;

  // 渠道 & 方式
  String? _purchaseChannel;
  String? _purchaseMethod;

  // 补充信息
  String _status = '使用中';

  // 保修期
  int _warrantyValue = 1;
  String _warrantyUnit = 'year'; // day | month | year | forever
  DateTime? _warrantyExpiry;

  // 图片附件 + 笔记
  List<String> _imagePaths = [];
  String _notes = '';

  // 特殊信息
  bool _includeInAssets = true;
  bool _includeInDailyCost = true;
  bool _autoEstimateResidual = false;

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _extraCostCtrl = TextEditingController();
  final _extraCostNoteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _specsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final i = widget.item!;
      _name = i.name;
      _price = i.price;
      _extraCost = i.extraCost;
      _extraCostNote = i.extraCostNote;
      _purchaseDate = i.purchaseDate;
      _categoryId = i.categoryId;
      _subCategoryId = i.subCategoryId;
      _imagePaths = List.from(i.imagePaths);
      _notes = i.notes ?? '';
      _purchaseChannel = i.purchaseChannel;
      _purchaseMethod = i.purchaseMethod;
      _warrantyExpiry = i.warrantyExpiry;
      _nameCtrl.text = i.name;
      _priceCtrl.text = i.price?.toString() ?? '';
      _extraCostCtrl.text = i.extraCost?.toString() ?? '';
      _extraCostNoteCtrl.text = i.extraCostNote ?? '';
      _locationCtrl.text = i.location ?? '';
      _specsCtrl.text = i.specifications ?? '';
      _notesCtrl.text = i.notes ?? '';
      if (i.warrantyExpiry != null) {
        _warrantyValue = i.warrantyExpiry!.difference(i.purchaseDate ?? DateTime.now()).inDays.clamp(1, 36500);
        _warrantyUnit = 'day';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _extraCostCtrl.dispose();
    _extraCostNoteCtrl.dispose();
    _locationCtrl.dispose();
    _specsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ====== 保修期计算 ======
  DateTime? get _computedWarrantyExpiry {
    if (_warrantyUnit == 'forever') return null;
    final base = _purchaseDate ?? DateTime.now();
    switch (_warrantyUnit) {
      case 'day': return base.add(Duration(days: _warrantyValue));
      case 'month': return DateTime(base.year, base.month + _warrantyValue, base.day);
      case 'year': return DateTime(base.year + _warrantyValue, base.month, base.day);
      default: return base.add(Duration(days: _warrantyValue));
    }
  }

  String get _warrantyLabel {
    if (_warrantyUnit == 'forever') return '永久保修';
    final unitLabel = {'day': '天', 'month': '个月', 'year': '年'}[_warrantyUnit] ?? '天';
    return '$_warrantyValue$unitLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditing ? '编辑物品' : '新增物品', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [TextButton(onPressed: _submit, child: const Text('完成', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(children: [
          const SizedBox(height: 8),
          _buildTemplateModule(),
          const SizedBox(height: 12),
          _buildBasicInfoModule(context),
          const SizedBox(height: 12),
          _buildChannelMethodModule(),
          const SizedBox(height: 12),
          _buildSupplementaryModule(),
          const SizedBox(height: 12),
          _buildLocationSpecsModule(),
          const SizedBox(height: 12),
          _buildSpecialModule(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ========== 模板 ==========
  Widget _buildTemplateModule() {
    final templates = ['二手资产', '虚拟资产', '临期商品', '金银首饰'];
    final tips = [
      '适用于电子数码，大件商品，能够实时获取二手估价',
      '适用于会员订阅，云存储，虚拟物品',
      '适用于食品、药品、化妆品等有保质期的商品',
      '适用于珠宝、金条、银饰等贵重物品',
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('物品模板', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(templates.length, (i) {
          final sel = _selectedTemplate == i;
          return GestureDetector(
            onTap: () => setState(() { _selectedTemplate = i; _applyTemplate(i); }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.bgCard, borderRadius: BorderRadius.circular(20), border: sel ? null : Border.all(color: AppColors.border)),
              child: Text(templates[i], style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            ),
          );
        })),
        const SizedBox(height: 10),
        Text(tips[_selectedTemplate], style: TextStyle(fontSize: 12, color: AppColors.textHint)),
      ])),
    );
  }

  void _applyTemplate(int idx) {
    if (_name.isEmpty) return; // don't override user input
    // 可选：根据模板预设分类、字段等
  }

  // ========== 基本信息 ==========
  Widget _buildBasicInfoModule(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildCoverImageUpload(),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 88, child: TextField(controller: _nameCtrl, onChanged: (v) => _name = v, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(labelText: '物品名称', hintText: '请输入物品名称', alignLabelWithHint: true), maxLines: 3))),
        ]),
        const SizedBox(height: 16),
        _buildRowField('购入价格', TextField(controller: _priceCtrl, keyboardType: TextInputType.number, onChanged: (v) => _price = double.tryParse(v), style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '请输入购入单价', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
        const Divider(height: 16),
        _buildRowField('额外费用', TextField(controller: _extraCostCtrl, keyboardType: TextInputType.number, onChanged: (v) => _extraCost = double.tryParse(v), style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '运费/关税等（记入总价）', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
        const Divider(height: 16),
        _buildRowField('费用说明', TextField(controller: _extraCostNoteCtrl, onChanged: (v) => _extraCostNote = v, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '例如：快递运费', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
        const Divider(height: 16),
        _buildRowField('购买日期', GestureDetector(
          onTap: () async { final d = await showDatePicker(context: context, initialDate: _purchaseDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setState(() => _purchaseDate = d); },
          child: Text(_purchaseDate != null ? DateFormat('yyyy年MM月dd日').format(_purchaseDate!) : '请选择', style: TextStyle(fontSize: 15, color: _purchaseDate != null ? AppColors.textPrimary : AppColors.textHint)),
        )),
        const Divider(height: 16),
        _buildRowField('物品分类', GestureDetector(
          onTap: () => _showCategoryPicker(context, provider),
          child: Row(children: [
            Icon(_iconForCategory(provider, _categoryId), size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(_categoryName(provider), style: TextStyle(fontSize: 15, color: _categoryId != null ? AppColors.textPrimary : AppColors.textHint)),
            const Spacer(), const Icon(Icons.chevron_right, color: AppColors.textHint),
          ]),
        )),
      ])),
    );
  }

  IconData _iconForCategory(ItemProvider provider, String? id) {
    if (id == null) return Icons.folder;
    final cat = provider.categories.where((c) => c.id == id).firstOrNull;
    if (cat == null) return Icons.folder;
    switch (cat.icon) {
      case 'phone_android': return Icons.phone_android;
      case 'kitchen': return Icons.kitchen;
      case 'medical_services': return Icons.medical_services;
      case 'diamond': return Icons.diamond;
      case 'card_membership': return Icons.card_membership;
      case 'checkroom': return Icons.checkroom;
      case 'book': return Icons.book;
      default: return Icons.folder;
    }
  }

  String _categoryName(ItemProvider provider) {
    if (_categoryId == null) return '请选择分类';
    final cat = provider.categories.where((c) => c.id == _categoryId).firstOrNull;
    return cat?.name ?? '请选择分类';
  }

  void _showCategoryPicker(BuildContext context, ItemProvider provider) {
    final subs = provider.subCategories.where((c) => c.parentId == _categoryId).toList();

    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        // 一级分类
        ...provider.categories.map((c) => ListTile(
          leading: Icon(_iconForCategory(provider, c.id), color: AppColors.primary),
          title: Text(c.name),
          trailing: _categoryId == c.id ? const Icon(Icons.check, color: AppColors.primary) : null,
          onTap: () { setState(() { _categoryId = c.id; _subCategoryId = null; }); setSt(() {}); Navigator.pop(ctx); },
        )),
        // 如果有二级分类
        if (subs.isNotEmpty) ...[
          const Divider(), const SizedBox(height: 8),
          const Text('二级分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ...subs.map((s) => ListTile(
            dense: true,
            title: Text(s.name, style: const TextStyle(fontSize: 14)),
            trailing: _subCategoryId == s.id ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
            onTap: () { setState(() => _subCategoryId = s.id); Navigator.pop(ctx); },
          )),
        ],
      ]))),
    );
  }

  // ========== 封面图 ==========
  Widget _buildCoverImageUpload() {
    final hasImage = _coverImagePath != null && _coverImagePath!.isNotEmpty;
    return GestureDetector(
      onTap: _showCoverImageOptions,
      child: Container(
        width: 88, height: 88,
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8), color: AppColors.bgSecondary, image: hasImage ? DecorationImage(image: FileImage(File(_coverImagePath!)), fit: BoxFit.cover) : null),
        child: hasImage ? null : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 24, color: AppColors.textHint), const SizedBox(height: 4), Text('封面图', style: TextStyle(fontSize: 11, color: AppColors.textHint))]),
      ),
    );
  }

  Future<void> _showCoverImageOptions() async {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12), const Text('选择封面图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary), title: const Text('从相册上传'), onTap: () { Navigator.pop(ctx); _pickFromGallery(); }),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.search, color: AppColors.info), title: const Text('互联网搜索'), onTap: () { Navigator.pop(ctx); _searchOnBaidu(); }),
        const SizedBox(height: 8),
      ]))),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked != null) setState(() => _coverImagePath = picked.path);
  }

  Future<void> _searchOnBaidu() async {
    final query = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '物品';
    final path = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => WebSearchScreen(searchQuery: query)));
    if (path != null && mounted) setState(() => _coverImagePath = path);
  }

  // ========== 购买渠道 & 方式 ==========
  Widget _buildChannelMethodModule() {
    final customChannels = _builtinChannels.toList()..addAll([]);
    final customMethods = _builtinMethods.toList()..addAll([]);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('购买信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // 购买渠道
        const Text('购买渠道', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          ..._builtinChannels.map((c) {
            final sel = _purchaseChannel == c;
            return GestureDetector(
              onTap: () => setState(() => _purchaseChannel = sel ? null : c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(16)),
                child: Text(c, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _addCustomChannel(),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: AppColors.textSecondary), const SizedBox(width: 2), Text('自定义', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
          ),
        ]),

        const SizedBox(height: 16),
        const Text('购买方式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          ..._builtinMethods.map((m) {
            final sel = _purchaseMethod == m;
            return GestureDetector(
              onTap: () => setState(() => _purchaseMethod = sel ? null : m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(16)),
                child: Text(m, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _addCustomMethod(),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: AppColors.textSecondary), const SizedBox(width: 2), Text('自定义', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
          ),
        ]),
      ])),
    );
  }

  void _addCustomChannel() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('添加购买渠道'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '输入渠道名称'), autofocus: true), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      TextButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) { setState(() => _purchaseChannel = ctrl.text.trim()); Navigator.pop(ctx); } }, child: const Text('确定')),
    ]));
  }

  void _addCustomMethod() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('添加购买方式'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '输入方式名称'), autofocus: true), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      TextButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) { setState(() => _purchaseMethod = ctrl.text.trim()); Navigator.pop(ctx); } }, child: const Text('确定')),
    ]));
  }

  // ========== 补充信息 ==========
  Widget _buildSupplementaryModule() {
    final statuses = ['使用中', '闲置', '已出售', '已损坏'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('补充信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // 物品状态
        _buildRowField('物品状态', GestureDetector(
          onTap: () => _showStatusPicker(statuses),
          child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _statusColor(_status).withAlpha(25), borderRadius: BorderRadius.circular(14)), child: Text(_status, style: TextStyle(fontSize: 13, color: _statusColor(_status), fontWeight: FontWeight.w600))),
            const Spacer(), const Icon(Icons.chevron_right, color: AppColors.textHint),
          ]),
        )),
        const Divider(height: 16),

        // 保修期
        _buildRowField('保修期', GestureDetector(
          onTap: () => _showWarrantyPicker(),
          child: Row(children: [
            Text(_warrantyLabel, style: const TextStyle(fontSize: 15)),
            const Spacer(), const Icon(Icons.chevron_right, color: AppColors.textHint),
          ]),
        )),
        const Divider(height: 16),

        // 过保日期
        _buildRowField('过保日期', GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _warrantyExpiry ?? _computedWarrantyExpiry ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2100));
            if (d != null) setState(() { _warrantyExpiry = d; _warrantyUnit = 'forever'; });
          },
          child: Row(children: [
            Text(_warrantyExpiry != null ? DateFormat('yyyy年MM月dd日').format(_warrantyExpiry!) : _computedWarrantyExpiry != null ? DateFormat('yyyy年MM月dd日').format(_computedWarrantyExpiry!) : '请设置', style: TextStyle(fontSize: 15, color: (_warrantyExpiry ?? _computedWarrantyExpiry) != null ? AppColors.textPrimary : AppColors.textHint)),
            const Spacer(), const Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
          ]),
        )),
        const Divider(height: 16),

        // 图片附件
        _buildRowField('图片附件', GestureDetector(
          onTap: _pickImages,
          child: Row(children: [Text(_imagePaths.isEmpty ? '无' : '${_imagePaths.length}张图片', style: TextStyle(fontSize: 15, color: _imagePaths.isEmpty ? AppColors.textHint : AppColors.textPrimary)), const Spacer(), const Icon(Icons.chevron_right, color: AppColors.textHint)]),
        )),
        const Divider(height: 16),

        // 备注说明
        _buildRowField('备注说明', TextField(controller: _notesCtrl, onChanged: (v) => _notes = v, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '请输入备注', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
      ])),
    );
  }

  void _showWarrantyPicker() {
    final unitLabels = {'day': '天', 'month': '月', 'year': '年', 'forever': '永久'};
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('设置保修期', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // 单位选择
        Wrap(spacing: 10, children: unitLabels.entries.map((e) {
          final sel = _warrantyUnit == e.key;
          return GestureDetector(
            onTap: () => setSheetState(() { _warrantyUnit = e.key; if (e.key == 'forever') _warrantyValue = 0; }),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(22)), child: Text(e.value, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? Colors.white : AppColors.textPrimary))),
          );
        }).toList()),

        if (_warrantyUnit != 'forever') ...[
          const SizedBox(height: 16),
          // 手动输入数字
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: TextEditingController(text: '$_warrantyValue'),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                decoration: const InputDecoration(border: InputBorder.none, hintText: '输入'),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) setSheetState(() => _warrantyValue = n);
                },
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Center(child: Text('${unitLabels[_warrantyUnit]}', style: const TextStyle(fontSize: 16))),
          const SizedBox(height: 8),
          if (_computedWarrantyExpiry != null) Center(child: Text('预计过保: ${DateFormat('yyyy-MM-dd').format(_computedWarrantyExpiry!)}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],

        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: () { setState(() {}); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('确定', style: TextStyle(fontSize: 16)))),
      ]))),
    );
  }

  void _showStatusPicker(List<String> statuses) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('选择物品状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 16),
      ...List.generate(statuses.length, (i) => ListTile(title: Text(statuses[i]), leading: Radio<String>(value: statuses[i], groupValue: _status, activeColor: AppColors.primary, onChanged: (v) { setState(() => _status = v!); Navigator.pop(ctx); }))),
    ])));
  }

  void _pickImages() { setState(() => _imagePaths = ['img1']); }

  Color _statusColor(String s) {
    switch (s) { case '使用中': return AppColors.accent; case '闲置': return AppColors.warning; case '已出售': return AppColors.textSecondary; case '已损坏': return AppColors.danger; default: return AppColors.accent; }
  }

  // ========== 特殊信息 ==========
  Widget _buildLocationSpecsModule() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('存放 & 规格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildRowField('存放位置', TextField(controller: _locationCtrl, onChanged: (v) {}, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '例如：客厅/书房', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
        const Divider(height: 16),
        _buildRowField('规格型号', TextField(controller: _specsCtrl, onChanged: (v) {}, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: '例如：256G/白色', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
      ])),
    );
  }

  Widget _buildSpecialModule() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('特殊信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 16),
        _buildToggleRow('计入资产', '按购入价格计入资产', _includeInAssets, (v) => setState(() => _includeInAssets = v)),
        const Divider(height: 16),
        _buildToggleRow('计入日均成本', null, _includeInDailyCost, (v) => setState(() => _includeInDailyCost = v)),
        const Divider(height: 16),
        _buildToggleRow('自动估算二手价格', '日均成本 = (购入价 - 二手价) / 使用天数', _autoEstimateResidual, (v) => setState(() => _autoEstimateResidual = v), showHelp: true),
      ])),
    );
  }

  // ========== 通用组件 ==========
  Widget _buildRowField(String label, Widget right) => SizedBox(height: 48, child: Row(children: [SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 15, color: AppColors.textPrimary))), Expanded(child: right)]));

  Widget _buildToggleRow(String label, String? subtitle, bool value, ValueChanged<bool> onChanged, {bool showHelp = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 15)),
      if (showHelp) ...[const SizedBox(width: 4), GestureDetector(onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日均成本 = (购入价 - 二手价) / 使用天数'))); }, child: const Icon(Icons.help_outline, size: 14, color: AppColors.textHint))],
      const Spacer(),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
    if (subtitle != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textHint))),
  ]);

  // ========== 提交 ==========
  void _submit() async {
    if (_name.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入物品名称'))); return; }
    if (_categoryId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类'))); return; }

    try {
      final provider = context.read<ItemProvider>();
      final effectiveExpiry = _warrantyExpiry ?? _computedWarrantyExpiry;
      final allImages = <String>[
        if (_coverImagePath != null && _coverImagePath!.isNotEmpty) _coverImagePath!,
        ..._imagePaths,
      ];
      final item = Item(
        id: widget.item?.id ?? _uuid.v4(), name: _name.trim(), categoryId: _categoryId!, subCategoryId: _subCategoryId,
        price: _price, extraCost: _extraCost, extraCostNote: _extraCostNote, purchaseDate: _purchaseDate, warrantyExpiry: effectiveExpiry,
        purchaseChannel: _purchaseChannel, purchaseMethod: _purchaseMethod,
        location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text.trim(),
        specifications: _specsCtrl.text.isEmpty ? null : _specsCtrl.text.trim(),
        notes: _notes.isEmpty ? null : _notes, imagePaths: allImages,
        residualValue: _autoEstimateResidual ? null : ((_price ?? 0) + (_extraCost ?? 0)) * 0.7,
      );
      if (_isEditing) {
        await provider.updateItem(item);
      } else {
        await provider.addItem(item);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? '已更新' : '已添加')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e'), duration: const Duration(seconds: 3)));
      }
    }
  }
}
