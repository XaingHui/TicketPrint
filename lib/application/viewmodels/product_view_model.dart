import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

import 'package:file_picker/file_picker.dart';

class ProductViewModel extends ChangeNotifier {
  final IProductRepository _repository;

  List<Product> _products = [];
  List<Product> get products => _products;

  // Search State
  String _searchQuery = '';
  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProductViewModel(this._repository);

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts();
    } catch (e) {
      _errorMessage = "Failed to load products: $e";
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        return result.files.single.path;
      }
    } catch (e) {
      _errorMessage = "Failed to pick image: $e";
      notifyListeners();
    }
    return null;
  }

  Future<void> addProduct(String name, double price, String unit, {String? imagePath}) async {
    try {
      final product = Product(
        id: const Uuid().v4(),
        name: name,
        price: price,
        unit: unit,
        imagePath: imagePath,
      );
      await _repository.addProduct(product);
      await loadProducts(); // Refresh list
    } catch (e) {
      _errorMessage = "Failed to add product: $e";
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      _errorMessage = "Failed to update product: $e";
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      _errorMessage = "Failed to delete product: $e";
      notifyListeners();
    }
  }
}
