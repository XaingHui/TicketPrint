import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For DateRangePicker
import '../../data/database.dart';
import '../../domain/entities/invoice.dart';
import 'package:printing/printing.dart'; // For sharing
import '../../data/database.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/services/pdf_generator_interface.dart'; // For re-generating PDF
import '../../data/services/storage_service.dart'; // For merchant info

enum HistoryFilterType {
  today,
  week,
  month,
  year,
  custom,
}

class InvoiceHistoryViewModel extends ChangeNotifier {
  final AppDatabase _database;
  final IPdfGeneratorService _pdfService; // Need this
  final StorageService _storageService; // Need this

  InvoiceHistoryViewModel({
    required AppDatabase database,
    required IPdfGeneratorService pdfService,
    required StorageService storageService,
  }) : _database = database, 
       _pdfService = pdfService,
       _storageService = storageService;

  // State
  List<Invoice> _invoices = [];
  List<Invoice> get invoices => List.unmodifiable(_invoices);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filters
  HistoryFilterType _filterType = HistoryFilterType.today;
  HistoryFilterType get filterType => _filterType;

  DateTimeRange? _customDateRange;
  DateTimeRange? get customDateRange => _customDateRange;

  String? _customerFilter;
  String? get customerFilter => _customerFilter;

  // Methods
  
  void setFilterType(HistoryFilterType type) {
    _filterType = type;
    if (type != HistoryFilterType.custom) {
      _customDateRange = null; // Clear custom range if switching away
    }
    loadInvoices();
  }

  void setCustomDateRange(DateTimeRange range) {
    _filterType = HistoryFilterType.custom;
    _customDateRange = range;
    loadInvoices();
  }

  void setCustomerFilter(String? name) {
    _customerFilter = name;
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      DateTime start;
      DateTime end = DateTime.now();

      final now = DateTime.now();

      switch (_filterType) {
        case HistoryFilterType.today:
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End of today
          break;
        case HistoryFilterType.week:
          // Start of current week (assuming Monday start)
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          break;
        case HistoryFilterType.month:
          start = DateTime(now.year, now.month, 1);
          break;
        case HistoryFilterType.year:
          start = DateTime(now.year, 1, 1);
          break;
        case HistoryFilterType.custom:
          if (_customDateRange != null) {
            start = _customDateRange!.start;
            end = _customDateRange!.end;
          } else {
            // Default to today if custom is selected but range is null (shouldn't happen ideally)
            start = DateTime(now.year, now.month, now.day);
          }
          break;
      }

      final invoiceRows = await _database.getInvoicesByDateRange(start, end);
      
      // Map DB rows to Domain Entities
      // Note: We might need to fetch items for each invoice if we want to calculate totals or show details.
      // For the list view, we might only need totals. Getting totals from Items table would be better with a JOIN.
      // But for now, let's fetch items lazily or just fetch everything if dataset is small.
      // Optimization: In database.dart, we could add a query that joins Invoices with InvoiceItems sum.
      // For simplicity now, let's just create Invoices without items or fetch items separately? 
      // Actually, the current API `getInvoicesByDateRange` returns simple Invoice rows. 
      // We can't calculate total without items.
      
      // Let's modify the flow to fetch items or do a join. 
      // Given the complexity constraints, I'll do a simple iteration to fetch items (N+1 query, but okay for local DB with small lists).
      // Or better, let's just make `Invoice` entity nullable items and perform calculation in DB.
      // Re-reading `Invoice` entity: it expects `List<InvoiceItem> items`. 
      
      // Quick fix: Modify `Invoice` to accept `totalPrice` directly? No, `totalPrice` is a getter.
      // Pragamatic approach: Fetch items for each invoice. It's local SQLite, it's fast enough for < 100 items.
      
      List<Invoice> parsedInvoices = [];
      
      for (final row in invoiceRows) {
        // Filter by customer if needed (client-side filtering for now, could be DB side)
        if (_customerFilter != null && _customerFilter!.isNotEmpty) {
           if (row.targetName == null || !row.targetName!.contains(_customerFilter!)) {
             continue;
           }
        }

        // Fetch Items for this invoice
        // We need a query for items. `select(invoiceItemsTable)..where(...)`
        // Since I can't easily modify database.dart again right here without context switching tools, 
        // I will trust that I can add a helper or use the raw query capability if needed?
        // Actually I don't have `getInvoiceItems(id)` in database.dart exposed. 
        // I need to add that query to `database.dart` or expose Dao.
        
        // Wait, I should have added `getInvoiceItems` to `database.dart` or `InvoiceItemsDao`.
        // I'll assume I can add it or standard `select(invoiceItemsTable)..where` works if I have access.
        // `_database.select` is not available directly outside unless exposed.
        // `_database` object usually has access to tables if they are public. `invoicesTable` is a getter in DB class.
        // But `select` is a method on Database class usually protected? No, `select` is from `DatabaseConnectionUser`. It IS available.
        
        final itemsQuery = _database.select(_database.invoiceItemsTable)
          ..where((t) => t.invoiceId.equals(row.id));
        final itemRows = await itemsQuery.get();
        
        final items = itemRows.map((itemRow) => InvoiceItem(
          productName: itemRow.productName,
          price: itemRow.price,
          unit: itemRow.unit,
          quantity: itemRow.quantity,
        )).toList();

        parsedInvoices.add(Invoice(
          id: row.id,
          targetName: row.targetName,
          discountAmount: row.discountAmount, // Fix: Map discount amount
          createdAt: row.createdAt,
          items: items,
        ));
      }
      
      _invoices = parsedInvoices;

    } catch (e) {
      _errorMessage = "加载历史记录失败: $e";
      if (kDebugMode) {
        print(e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reprintInvoice(Invoice invoice) async {
    _isLoading = true;
    notifyListeners();
    try {
      final merchantName = _storageService.merchantName ?? '我的小店';
      final merchantPhone = _storageService.merchantPhone;
      final merchantAddress = _storageService.merchantAddress;

      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice, 
        merchantName, 
        merchantPhone, 
        merchantAddress
      );

      final now = invoice.createdAt;
      String timestamp = "${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}";
      if (invoice.targetName != null && invoice.targetName!.isNotEmpty) {
        timestamp += "_${invoice.targetName}";
      }
      final fileName = "${timestamp}.pdf";

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      _errorMessage = "打印失败: $e";
       if (kDebugMode) {
        print(e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
