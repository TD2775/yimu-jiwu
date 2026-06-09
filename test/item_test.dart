import 'package:flutter_test/flutter_test.dart';
import 'package:yimu_jiwu/models/item.dart';
import 'package:yimu_jiwu/utils/helpers.dart';

void main() {
  group('Item model', () {
    test('should calculate daily cost correctly', () {
      final item = Item(
        id: '1',
        name: '测试物品',
        categoryId: 'cat1',
        price: 1000,
        purchaseDate: DateTime.now().subtract(const Duration(days: 100)),
        residualValue: 200,
      );
      final cost = item.dailyCost;
      expect(cost, isNotNull);
      expect(cost, moreOrLessEquals(8.0, epsilon: 0.5));
    });

    test('should detect low stock', () {
      final item = Item(
        id: '1',
        name: '低库存物品',
        categoryId: 'cat1',
        stock: 0,
        lowStockThreshold: 2,
      );
      expect(item.isLowStock, isTrue);
    });

    test('should detect expiry warning within 30 days', () {
      final item = Item(
        id: '1',
        name: '快过期物品',
        categoryId: 'cat1',
        shelfLifeExpiry: DateTime.now().add(const Duration(days: 10)),
      );
      expect(item.hasExpiryWarning, isTrue);
    });
  });

  group('Helpers', () {
    test('formatDate should return yyyy-MM-dd', () {
      expect(formatDate(DateTime(2025, 6, 15)), '2025-06-15');
    });

    test('formatPrice should format correctly', () {
      expect(formatPrice(1234.56), '¥1234.56');
      expect(formatPrice(10000), '¥1.0万');
    });
  });
}
