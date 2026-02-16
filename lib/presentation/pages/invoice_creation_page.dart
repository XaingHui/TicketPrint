import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import 'dart:async';
import '../../application/viewmodels/product_view_model.dart';
import '../../application/viewmodels/invoice_view_model.dart';
import '../../domain/entities/product.dart';
import 'invoice_history_page.dart';

class InvoiceCreationPage extends StatefulWidget {
  const InvoiceCreationPage({super.key});

  @override
  State<InvoiceCreationPage> createState() => _InvoiceCreationPageState();
}

class _InvoiceCreationPageState extends State<InvoiceCreationPage> {
  late InvoiceViewModel _invoiceVM;

  @override
  void initState() {
    super.initState();
    _invoiceVM = context.read<InvoiceViewModel>();
    
    // Refresh products on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
    });
    
    // Listen for messages (Success/Error)
    _invoiceVM.addListener(_onInvoiceVMChanged);
  }

  @override
  void dispose() {
    _invoiceVM.removeListener(_onInvoiceVMChanged);
    super.dispose();
  }

  void _onInvoiceVMChanged() {
    final vm = context.read<InvoiceViewModel>();
    if (!vm.isLoading && vm.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: vm.errorMessage!.startsWith('已保存') ? Colors.green : Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      // Consume the message so it doesn't show again on subsequent updates
      vm.clearMessage();
    }
  }

  void _showQuantityDialog(BuildContext context, Product product, double currentQty, InvoiceViewModel invoiceVM) {
    final controller = TextEditingController(text: currentQty > 0 ? currentQty.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('输入 ${product.name} 数量'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
          autofocus: true,
          decoration: InputDecoration(
            labelText: '数量',
            suffixText: product.unit,
          ),
          onSubmitted: (_) {
             final qty = double.tryParse(controller.text) ?? 0.0;
             invoiceVM.updateProductQuantity(product.name, product.price, product.unit, qty);
             Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(controller.text) ?? 0.0;
              invoiceVM.updateProductQuantity(product.name, product.price, product.unit, qty);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSettleDialog(BuildContext context, InvoiceViewModel invoiceVM) {
    if (invoiceVM.currentItems.isEmpty) return;

    final total = invoiceVM.totalAmount;
    // Initialize with current discount if any (though usually 0 on fresh start)
    // We can use a local state for the dialog properties
    double discount = invoiceVM.discountAmount; 
    double finalAmount = total - discount;

    final discountController = TextEditingController(text: discount == 0 ? '' : discount.toStringAsFixed(2));
    final finalController = TextEditingController(text: finalAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结算确认'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("原价总计:"),
                  Text("¥${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Gap(16),
              
              // Discount Input
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '折扣 / 优惠金额',
                  prefixText: '- ¥',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final d = double.tryParse(value) ?? 0.0;
                  discount = d;
                  finalAmount = total - discount;
                  finalController.text = finalAmount.toStringAsFixed(2);
                },
              ),
              const Gap(12),
              
              // Final Amount Input (Rounding)
              TextField(
                controller: finalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '实收金额 (抹零)',
                  prefixText: '¥',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final f = double.tryParse(value) ?? 0.0;
                  finalAmount = f;
                  discount = total - finalAmount;
                  discountController.text = discount.toStringAsFixed(2);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton.icon(
            onPressed: () {
               // Update VM state
               invoiceVM.setDiscountAmount(discount);
               // Proceed to Save and Print
               Navigator.pop(context);
               invoiceVM.saveAndPrintInvoice();
            }, 
            icon: const Icon(Icons.print),
            label: const Text('确认并打印'),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelectDialog(BuildContext context, InvoiceViewModel invoiceVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择或添加客户'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add Customer Input
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                    return invoiceVM.getCustomerSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  invoiceVM.setTargetCustomer(selection);
                  Navigator.pop(context);
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: () {
                      onEditingComplete();
                      if (controller.text.isNotEmpty) {
                        invoiceVM.setTargetCustomer(controller.text);
                        Navigator.pop(context);
                      }
                    },
                    decoration: InputDecoration(
                       labelText: '输入客户名称',
                       hintText: '输入新名称或从列表选择',
                       border: const OutlineInputBorder(),
                       suffixIcon: IconButton(
                         icon: const Icon(Icons.check_circle),
                         onPressed: () {
                           if (controller.text.isNotEmpty) {
                             invoiceVM.setTargetCustomer(controller.text);
                             Navigator.pop(context);
                           }
                         },
                       ),
                    ),
                  );
                },
              ),
              const Gap(16),
              const Divider(),
              const Align(alignment: Alignment.centerLeft, child: Text("常用客户 (示例)")),
              // Simplified list for now, ideally populated by VM
              // Since Autocomplete handles suggestions, we might just rely on that or 
              // show a list of recent customers if VM provides it.
              // For now, let's keep it simple with just the Autocomplete which acts as both search and add.
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("请在上方输入框输入名称，系统会自动联想已存客户。", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              invoiceVM.setTargetCustomer(null);
              Navigator.pop(context);
            }, 
            child: const Text('清除选择'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选品开票'),
        actions: [
          // Customer Autocomplete (Simplified as a button to show dialog or directly in title? 
          // Title might be too small. Let's put it in the body or a dedicated button)
          // Actually, let's replace the title with the customer input or add it to the body.
          // Let's add a history button first.
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '开票记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductViewModel>().loadProducts(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空已选',
            onPressed: () {
               context.read<InvoiceViewModel>().clearItems();
            },
          ),
        ],
      ),
      body: Consumer2<ProductViewModel, InvoiceViewModel>(
        builder: (context, productVM, invoiceVM, child) {
          if (productVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = productVM.filteredProducts;
          
          return Column(
            children: [
              // Top Bar: Search & Customer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Product Search
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '搜索商品...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          productVM.searchProducts(value);
                        },
                      ),
                    ),
                    const Gap(12),
                    // Customer Selection Button
                    FilledButton.tonalIcon(
                      onPressed: () => _showCustomerSelectDialog(context, invoiceVM),
                      icon: const Icon(Icons.person),
                      label: Text(invoiceVM.targetCustomer ?? '选择客户'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),

              if (products.isEmpty)
                 const Expanded(child: Center(child: Text("没有找到商品"))),

              if (products.isNotEmpty)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Mobile: ~2 columns, Tablet: ~4-5, Desktop: ~6+
                    // Assuming min width per card ~160
                    final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 6);
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, 
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.62, // Much taller for safety
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final color = Colors.primaries[product.name.hashCode % Colors.primaries.length];
                        final hasImage = product.imagePath != null && File(product.imagePath!).existsSync();
                        final currentQty = invoiceVM.getProductQuantity(product.name);
                        
                        return Card(
                          elevation: 0, 
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              invoiceVM.addItem(product.name, product.price, product.unit, 1);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image
                                Expanded(
                                  flex: 5, // More space for image
                                  child: hasImage 
                                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                                    : Container(
                                        color: color.withOpacity(0.1),
                                        child: Center(
                                          child: Text(
                                            product.name.isNotEmpty ? product.name[0] : '?',
                                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                      ),
                                ),
                                // Info & Actions
                                Expanded(
                                  flex: 4, // Enough space for text + buttons
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Name (Safe)
                                        Text(
                                          product.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2, // Allow 2 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Gap(4),
                                        // Price (Safe)
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '¥${product.price} / ${product.unit}',
                                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                                          ),
                                        ),
                                        const Spacer(), // Push buttons to bottom
                                        // Quantity Selector
                                        Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: currentQty > 0 ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                                            borderRadius: BorderRadius.circular(18),
                                            border: currentQty > 0 ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _QuickAdjustButton(
                                                icon: Icons.remove,
                                                onPressed: currentQty > 0 
                                                  ? () => invoiceVM.updateProductQuantity(product.name, product.price, product.unit, currentQty - 1)
                                                  : null,
                                                enabled: currentQty > 0,
                                                iconSize: 18,
                                                // Make button transparent to blend with container
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: currentQty > 0 ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey,
                                              ),
                                              
                                              // Qty Text
                                              InkWell(
                                                onTap: () => _showQuantityDialog(context, product, currentQty, invoiceVM),
                                                child: Padding(
                                                   padding: const EdgeInsets.symmetric(horizontal: 4),
                                                   child: Text(
                                                    currentQty > 0 ? currentQty.toStringAsFixed(0) : "0",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold, 
                                                      fontSize: 16,
                                                      color: currentQty > 0 ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              _QuickAdjustButton(
                                                icon: Icons.add,
                                                onPressed: () => invoiceVM.addItem(product.name, product.price, product.unit, 1),
                                                iconSize: 18,
                                                backgroundColor: Colors.transparent, // Blend
                                                foregroundColor: currentQty > 0 ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<InvoiceViewModel>(
        builder: (context, invoiceVM, child) {
           return Container(
             padding: const EdgeInsets.all(16.0),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.1),
                   blurRadius: 10,
                   offset: const Offset(0, -5),
                 )
               ],
             ),
             child: SafeArea(
               child: Row(
                 children: [
                   Column(
                     mainAxisSize: MainAxisSize.min,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("合计金额", style: TextStyle(fontSize: 14, color: Colors.grey)),
                       Text(
                         "¥${invoiceVM.totalAmount.toStringAsFixed(2)}",
                         style: TextStyle(
                           fontSize: 24, 
                           fontWeight: FontWeight.bold,
                           color: Theme.of(context).colorScheme.primary,
                         ),
                       ),
                     ],
                   ),
                   const Spacer(),
                   FilledButton.icon(
                     onPressed: invoiceVM.currentItems.isEmpty 
                       ? null 
                       : () {
                         // Open Settle Dialog instead of direct print
                         _showSettleDialog(context, invoiceVM);
                       },
                     icon: const Icon(Icons.print),
                     label: const Text("结算并打印", style: TextStyle(fontSize: 18)),
                     style: FilledButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                     ),
                   )
                 ],
               ),
             ),
           );
        },
      ),
    );
  }
}

class _QuickAdjustButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;

  const _QuickAdjustButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 18.0,
  });

  @override
  State<_QuickAdjustButton> createState() => _QuickAdjustButtonState();
}

class _QuickAdjustButtonState extends State<_QuickAdjustButton> {
  Timer? _timer;

  void _startTimer() {
    _stopTimer();
    // Initial delay before rapid fire
    _timer = Timer(const Duration(milliseconds: 400), () {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        widget.onPressed?.call();
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enabled ? (_) => _startTimer() : null,
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressCancel: () => _stopTimer(),
      child: IconButton.filledTonal(
        // We use onPressed for the single tap.
        onPressed: widget.enabled ? widget.onPressed : null,
        icon: Icon(widget.icon, size: widget.iconSize),
        constraints: BoxConstraints(minWidth: widget.iconSize * 2, minHeight: widget.iconSize * 2),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
        ),
      ),
    );
  }
}
