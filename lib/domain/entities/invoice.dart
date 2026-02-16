import 'package:equatable/equatable.dart';
import 'invoice_item.dart';

class Invoice extends Equatable {
  final String id;
  final String? targetName; // NEW: Customer Name
  final double discountAmount; // NEW: Discount
  final DateTime createdAt;
  final List<InvoiceItem> items;
  
  double get totalPrice => items.fold(0, (sum, item) => sum + item.total);
  double get finalPrice => totalPrice - discountAmount;

  const Invoice({
    required this.id,
    this.targetName,
    this.discountAmount = 0.0,
    required this.createdAt,
    this.items = const [],
  });

  @override
  List<Object?> get props => [id, targetName, discountAmount, createdAt, items];

  Invoice copyWith({
    String? id,
    String? targetName,
    double? discountAmount,
    DateTime? createdAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      targetName: targetName ?? this.targetName,
      discountAmount: discountAmount ?? this.discountAmount,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
