import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final String productName;
  final double price;
  final String unit;
  final double quantity;
  
  // 小计通常是计算出来的，但在持久化时也可以存储以防价格变动
  // 这里作为 getter 动态计算，或者由外部传入
  double get total => price * quantity;

  const InvoiceItem({
    required this.productName,
    required this.price,
    required this.unit,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productName, price, unit, quantity];
  
  // 便捷方法：复制并修改
  InvoiceItem copyWith({
    String? productName,
    double? price,
    String? unit,
    double? quantity,
  }) {
    return InvoiceItem(
      productName: productName ?? this.productName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }
}
