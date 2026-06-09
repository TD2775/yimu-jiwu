import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../utils/constants.dart';

/// 标签选择器组件
class TagPicker extends StatelessWidget {
  final List<String> selectedIds;
  final List<Tag> tags;
  final ValueChanged<List<String>> onChanged;
  final void Function(String name, int color)? onAddTag;

  const TagPicker({
    super.key,
    required this.selectedIds,
    required this.tags,
    required this.onChanged,
    this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...tags.map((tag) => _tagChip(tag)),
            if (onAddTag != null)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('新建标签'),
                onPressed: () => _showAddDialog(context),
              ),
          ],
        ),
      ],
    );
  }

  Widget _tagChip(Tag tag) {
    final selected = selectedIds.contains(tag.id);
    return FilterChip(
      label: Text(tag.name),
      selected: selected,
      onSelected: (sel) {
        final list = List<String>.from(selectedIds);
        if (sel) {
          list.add(tag.id);
        } else {
          list.remove(tag.id);
        }
        onChanged(list);
      },
      selectedColor: Color(tag.color).withAlpha(60),
      checkmarkColor: Color(tag.color),
      labelStyle: TextStyle(
        color: selected ? Color(tag.color) : AppColors.textPrimary,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? Color(tag.color) : AppColors.divider,
        width: 0.5,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selectedColor = AppColors.tagColors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: '标签名称'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppColors.tagColors.map((c) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selectedColor == c
                          ? Border.all(color: AppColors.textPrimary, width: 2.5)
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && onAddTag != null) {
                  onAddTag!(nameCtrl.text.trim(), selectedColor);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}
