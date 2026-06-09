# 一木记物 - 物品生命周期管理 App

Flutter 复刻版，完全开源免费。

## 功能模块

| 模块 | 说明 |
|------|------|
| 📦 物品管理 | 多品类物品 CRUD、一级/二级分类、自定义标签 |
| 🖼️ 三种展示 | 列表模式 / 瀑布流模式 / 极简模式 |
| ⏰ 到期提醒 | 保质期、保修期、会员到期，本地推送通知 |
| 📅 日历视图 | 购买日期、到期日的时间线呈现 |
| 💰 成本分析 | 自动估算残值 + 日均使用成本计算 |
| 📊 库存管理 | 库存数量、低库存预警、快捷调整 |
| 🔄 借出管理 | 借出 / 归还 / 续借 / 丢失状态流转 |
| 📈 统计图表 | 分类饼图、月度消费柱图、位置分布 |

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **数据库**: SQLite (sqflite)
- **图表**: fl_chart
- **日历**: table_calendar
- **通知**: flutter_local_notifications

## 运行

```bash
flutter pub get
flutter run
```

## 项目结构

```
lib/
├── main.dart              # 入口
├── app.dart               # MaterialApp + 底部导航
├── models/                # 数据模型
│   ├── item.dart          # 物品模型
│   ├── category.dart      # 分类模型
│   ├── tag.dart           # 标签模型
│   ├── lending.dart       # 借出模型
│   └── reminder.dart      # 提醒模型
├── services/              # 服务层
│   ├── database_service.dart  # SQLite 数据库
│   └── notification_service.dart # 本地通知
├── providers/             # 状态管理
│   └── item_provider.dart # 核心 Provider
├── screens/               # 页面
│   ├── home_screen.dart         # 首页
│   ├── item_detail_screen.dart  # 物品详情
│   ├── add_edit_item_screen.dart# 添加/编辑物品
│   ├── calendar_screen.dart     # 日历视图
│   ├── stats_screen.dart        # 统计页
│   ├── settings_screen.dart     # 设置
│   └── category_manage_screen.dart # 分类管理
├── widgets/               # 组件
│   ├── item_card.dart           # 物品卡片
│   ├── home_header.dart         # 首页概览条
│   ├── tag_picker.dart          # 标签选择器
│   ├── image_picker_grid.dart   # 图片选择
│   └── lending_card.dart        # 借出卡片
└── utils/                 # 工具
    ├── constants.dart     # 颜色/主题
    └── helpers.dart       # 格式化函数
```
