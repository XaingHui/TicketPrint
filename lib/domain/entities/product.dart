import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g., "斤", "个", "箱"
  final String? imagePath; // NEW: Image Path

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.imagePath,
  });

  @override
  List<Object?> get props => [id, name, price, unit, imagePath];
}
