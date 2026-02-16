import '../entities/product.dart';

/// 基础计算策略接口
/// 允许未来扩展不同的行业计算逻辑（由于是水果、建材等不同行业，计算方式可能略有不同）
abstract class BaseCalculationStrategy {
  /// 计算单个商品的总价
  /// [price] 单价
  /// [quantity] 数量
  /// [discount] 折扣 (0.0 - 1.0), 默认 1.0 即无折扣
  double calculateItemTotal(double price, double quantity, {double discount = 1.0});

  /// 格式化价格显示
  String formatPrice(double price);
}

class DefaultCalculationStrategy implements BaseCalculationStrategy {
  @override
  double calculateItemTotal(double price, double quantity, {double discount = 1.0}) {
    return price * quantity * discount;
  }

  @override
  String formatPrice(double price) {
    return price.toStringAsFixed(2);
  }
}
