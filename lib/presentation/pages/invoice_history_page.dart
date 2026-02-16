import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // For date formatting display
import '../../application/viewmodels/invoice_history_view_model.dart';
import '../../domain/entities/invoice.dart';
import '../../presentation/widgets/themed_scaffold.dart';

class InvoiceHistoryPage extends StatefulWidget {
  const InvoiceHistoryPage({super.key});

  @override
  State<InvoiceHistoryPage> createState() => _InvoiceHistoryPageState();
}

class _InvoiceHistoryPageState extends State<InvoiceHistoryPage> {
  final _customerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceHistoryViewModel>().loadInvoices();
    });
    _customerSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<InvoiceHistoryViewModel>().setCustomerFilter(_customerSearchController.text);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final vm = context.read<InvoiceHistoryViewModel>();
    final initialDateRange = vm.customDateRange ?? DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
    );

    if (picked != null) {
      vm.setCustomDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('开票记录'),
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: () => context.read<InvoiceHistoryViewModel>().loadInvoices(),
           )
        ],
      ),
      body: Consumer<InvoiceHistoryViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // Filters Section
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Time Filter Toggles
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: SegmentedButton<HistoryFilterType>(
                          segments: const [
                            ButtonSegment(value: HistoryFilterType.today, label: Text('今日')),
                            ButtonSegment(value: HistoryFilterType.week, label: Text('本周')),
                            ButtonSegment(value: HistoryFilterType.month, label: Text('本月')),
                            ButtonSegment(value: HistoryFilterType.year, label: Text('今年')),
                            ButtonSegment(value: HistoryFilterType.custom, label: Text('自定义')),
                          ],
                          selected: {vm.filterType},
                          onSelectionChanged: (Set<HistoryFilterType> newSelection) {
                            if (newSelection.first == HistoryFilterType.custom) {
                              _pickDateRange(context);
                            } else {
                              vm.setFilterType(newSelection.first);
                            }
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // Max compactness
                            padding: WidgetStateProperty.all(EdgeInsets.zero), // Remove internal padding
                          ),
                        ),
                      ),
                      
                      const Gap(8),
                      
                      // Custom Date Range Display / Re-pick
                      if (vm.filterType == HistoryFilterType.custom && vm.customDateRange != null)
                        TextButton.icon(
                          onPressed: () => _pickDateRange(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            "${DateFormat('yyyy-MM-dd').format(vm.customDateRange!.start)} 至 ${DateFormat('yyyy-MM-dd').format(vm.customDateRange!.end)}",
                          ),
                        ),

                      const Gap(4),
                      
                      // Customer Filter
                      TextField(
                        controller: _customerSearchController,
                        decoration: InputDecoration(
                          hintText: '搜索客户名称...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _customerSearchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _customerSearchController.clear()) 
                            : null,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading / Error / List
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (vm.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vm.errorMessage != null) {
                      return Center(child: Text(vm.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
                    }
                    if (vm.invoices.isEmpty) {
                      return const Center(child: Text('暂无开票记录'));
                    }

                    return ListView.builder(
                      itemCount: vm.invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = vm.invoices[index];
                        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                               // Show details or quick print dialog
                               _showInvoiceOptions(context, invoice);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.targetName?.isNotEmpty == true ? invoice.targetName! : "匿名散客",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: invoice.targetName?.isNotEmpty == true ? null : Colors.grey,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        dateFormat.format(invoice.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '¥${invoice.totalPrice.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${invoice.items.length} 件商品',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showInvoiceOptions(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("票据操作: ${invoice.targetName ?? '匿名'}"),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('重新打印 / 分享'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<InvoiceHistoryViewModel>().reprintInvoice(invoice);
                },
              ),
               // Can add more options like "Delete" (if implemented) or "View Details"
            ],
          ),
        );
      },
    );
  }
}
