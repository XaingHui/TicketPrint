import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:printing/printing.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/services/pdf_generator_interface.dart';
import '../../data/services/storage_service.dart';
import '../../domain/interfaces/base_calculation_strategy.dart';
import '../../data/database.dart';
import '../../data/services/storage_service.dart';

class InvoiceViewModel extends ChangeNotifier {
  final AppDatabase _database;
  final IPdfGeneratorService _pdfService;
  final BaseCalculationStrategy _calculationStrategy;
  final StorageService _storageService;

  InvoiceViewModel({
    required AppDatabase database,
    required IPdfGeneratorService pdfService,
    required BaseCalculationStrategy calculationStrategy,
    required StorageService storageService,
  })  : _database = database,
        _pdfService = pdfService,
        _calculationStrategy = calculationStrategy,
        _storageService = storageService;

  // State
  List<InvoiceItem> _currentItems = [];
  List<InvoiceItem> get currentItems => List.unmodifiable(_currentItems);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Methods

  /// 添加商品条目
  /// 添加商品条目 (累加数量)
  Future<void> addItem(String name, double price, String unit, double quantity) async {
    // Check stock
    final product = await _database.getProductByName(name);
    if (product != null) {
      final currentInCart = getProductQuantity(name);
      final totalRequested = currentInCart + quantity;
      
      if (totalRequested > product.stockQuantity) {
        _errorMessage = "库存不足! ${name} 余量: ${product.stockQuantity}";
        notifyListeners();
        return;
      }
    }

    final existingIndex = _currentItems.indexWhere((item) => item.productName == name);
    if (existingIndex != -1) {
      final currentQty = _currentItems[existingIndex].quantity;
      updateProductQuantity(name, price, unit, currentQty + quantity);
    } else {
      updateProductQuantity(name, price, unit, quantity);
    }
  }

  /// 移除商品条目
  void removeItem(int index) {
    if (index >= 0 && index < _currentItems.length) {
      _currentItems.removeAt(index);
      notifyListeners();
    }
  }

  /// 更新商品数量 (用于选品页面)
  /// 如果 quantity <= 0，则移除该商品
  Future<void> updateProductQuantity(String productName, double price, String unit, double quantity) async {
    final existingIndex = _currentItems.indexWhere((item) => item.productName == productName);

    if (quantity <= 0) {
      if (existingIndex != -1) {
        _currentItems.removeAt(existingIndex);
        notifyListeners();
      }
      return;
    }
    
    // Check stock for direct update
    final product = await _database.getProductByName(productName);
    if (product != null) {
      if (quantity > product.stockQuantity) {
         _errorMessage = "库存不足! ${productName} 余量: ${product.stockQuantity}";
         notifyListeners();
         // Optionally clamp quantity? Or just return?
         // Let's just return for now, preventing the update.
         // But we might need to reset the UI if it was a text input? 
         // For now, just error message.
         return;
      }
    }

    if (existingIndex != -1) {
      // Update existing
      _currentItems[existingIndex] = InvoiceItem(
        productName: productName,
        price: price, // Update price if changed in product? checking... usually price snapshot.
        unit: unit,
        quantity: quantity,
      );
    } else {
      // Add new
      _currentItems.add(InvoiceItem(
        productName: productName,
        price: price,
        unit: unit,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  /// 获取商品当前在购物车中的数量
  double getProductQuantity(String productName) {
    final item = _currentItems.firstWhere(
      (item) => item.productName == productName,
      orElse: () => const InvoiceItem(productName: '', price: 0, unit: '', quantity: 0),
    );
    return item.quantity;
  }
  
  /// 清空购物车
  void clearItems() {
    _currentItems.clear();
    notifyListeners();
  }

  /// 计算当前总价
  double get totalAmount {
    return _currentItems.fold(0, (sum, item) => sum + item.total);
  }

  // Discount Logic
  double _discountAmount = 0.0;
  double get discountAmount => _discountAmount;

  void setDiscountAmount(double amount) {
    if (amount < 0) amount = 0;
    if (amount > totalAmount) amount = totalAmount; // Cap at total? Or allow negative? Usually cap.
    _discountAmount = amount;
    notifyListeners();
  }

  /// 计算应收金额 (Final Amount)
  double get finalAmount => totalAmount - _discountAmount;

  String? _targetCustomer;
  String? get targetCustomer => _targetCustomer;

  void setTargetCustomer(String? name) {
    _targetCustomer = name;
    notifyListeners();
  }

  /// 获取所有客户列表 (用于自动补全)
  Future<List<String>> getCustomerSuggestions(String query) async {
    final allCustomers = await _database.getAllCustomers();
    return allCustomers
        .map((e) => e.name)
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 保存当前票据并生成 PDF
  Future<void> saveAndPrintInvoice({VoidCallback? onSaved}) async {
    if (_currentItems.isEmpty) {
      _errorMessage = "票据为空";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invoiceId = const Uuid().v4();
      final now = DateTime.now();
      final customerName = _targetCustomer;
      final discount = _discountAmount; // Capture current discount

      // 1. Transaction to save Invoice, Items and Customer to Database, AND Deduct Stock
      await _database.transaction(() async {
        await _database.insertInvoice(
          InvoicesTableCompanion(
            id: drift.Value(invoiceId),
            targetName: drift.Value(customerName),
            discountAmount: drift.Value(discount), // Save Discount
            createdAt: drift.Value(now),
          ),
        );

        for (final item in _currentItems) {
          await _database.insertInvoiceItem(
             InvoiceItemsTableCompanion(
              invoiceId: drift.Value(invoiceId),
              productName: drift.Value(item.productName),
              price: drift.Value(item.price),
              unit: drift.Value(item.unit),
              quantity: drift.Value(item.quantity),
            ),
          );
          
          // Deduct Stock
          final product = await _database.getProductByName(item.productName);
          if (product != null) {
            final newStock = product.stockQuantity - item.quantity.toInt();
            // We assume quantity is integer for stock, but InvoiceItem has double.
            // If selling 1.5kg, how does it affect "quantity" which is integer?
            // "quantity" in product table IS integer.
            // If user sells by weight (1.5kg), stock tracking might need to be double or ignored?
            // User requested "stock - 10", implying integer count (boxes/pieces).
            // Let's cast to int for now.
             await _database.updateProductStock(item.productName, newStock);
          }
        }

        // Save Customer if new
        if (customerName != null && customerName.isNotEmpty) {
          final existing = await _database.getCustomerByName(customerName);
          if (existing == null) {
            await _database.insertCustomer(
              CustomersTableCompanion(
                id: drift.Value(const Uuid().v4()),
                name: drift.Value(customerName),
                createdAt: drift.Value(now),
              ),
            );
          }
        }
      });

      // Transaction successful, trigger callback (e.g. to refresh stock)
      onSaved?.call();

      // 2. Prepare Data for PDF
      final invoiceForPdf = Invoice(
        id: invoiceId,
        targetName: customerName,
        discountAmount: discount, // Pass to Entity
        items: List.from(_currentItems),
        createdAt: now,
      );
      
      final merchantName = _storageService.merchantName ?? '我的小店';
      final merchantPhone = _storageService.merchantPhone;
      final merchantAddress = _storageService.merchantAddress;

      // 3. Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoiceForPdf, 
        merchantName, 
        merchantPhone, 
        merchantAddress
      );
      
      // 4. Print/Export
      // Format: yyyyMMdd_HHmm_Customer.pdf or just timestamp
      String timestamp = "${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}";
      if (customerName != null && customerName.isNotEmpty) {
        timestamp += "_$customerName";
      }
      final fileName = "${timestamp}.pdf";

      final savePath = _storageService.savePath;
      bool saveSuccess = false;
      
      if (savePath != null) {
        try {
          final fullPath = p.join(savePath, fileName);
          final file = File(fullPath);
          await file.writeAsBytes(pdfBytes);
          _errorMessage = "已保存至: $fullPath";
          saveSuccess = true;
          notifyListeners();
        } catch (e) {
          // Fallback if writing fails (e.g. Permission Denied on Android 10+)
          if (kDebugMode) print("File save failed: $e, falling back to share.");
          _errorMessage = "默认路径保存失败，请手动保存";
        }
      } 
      
      if (!saveSuccess) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      }
      
      // 5. Cleanup
      _currentItems.clear();
      _targetCustomer = null; 
      _discountAmount = 0.0; // Reset discount
      // _errorMessage = null; 

    } catch (e, s) {
      _errorMessage = "保存失败: $e";
      if (kDebugMode) {
        print(e);
        print(s);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
