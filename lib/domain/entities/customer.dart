import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, createdAt];
}
