import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../application/viewmodels/product_view_model.dart';
import '../../domain/entities/product.dart';
import 'package:file_picker/file_picker.dart'; // Ensure file_picker is imported if used, or just dart:io for File
import 'dart:io';
import '../../presentation/widgets/themed_scaffold.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load products when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
    });
  }

  void _showAddEditDialog(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? '个');
    final stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0'); // Stock Input
    String? selectedImagePath = product?.imagePath;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? '添加商品' : '编辑商品'),
            content: SizedBox(
              width: 500, 
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker (Top)
                    GestureDetector(
                      onTap: () async {
                         final result = await FilePicker.platform.pickFiles(type: FileType.image);
                         if (result != null) {
                           setState(() => selectedImagePath = result.files.single.path);
                         }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120, // Slightly larger
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              image: selectedImagePath != null 
                                ? DecorationImage(image: FileImage(File(selectedImagePath!)), fit: BoxFit.cover)
                                : null,
                            ),
                            child: selectedImagePath == null 
                              ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 40)
                              : null,
                          ),
                          if (selectedImagePath != null)
                            TextButton.icon(
                              onPressed: () => setState(() => selectedImagePath = null),
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              label: const Text("清除图片", style: TextStyle(color: Colors.red)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            )
                        ],
                      ),
                    ),
                    const Gap(24),
                    // Inputs (Below)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '商品名称',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: '单价 (¥)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextField( // Stock Input
                            controller: stockController,
                            decoration: const InputDecoration(
                              labelText: '库存余量',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: '单位',
                        hintText: '如: 个, 箱, 斤',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                  final unit = unitController.text.trim();
                  final stock = int.tryParse(stockController.text.trim()) ?? 0;
                  
                  if (name.isEmpty || price < 0 || unit.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('请填写完整的商品信息')),
                     );
                     return;
                  }
    
                  final viewModel = context.read<ProductViewModel>();
                  if (product == null) {
                    viewModel.addProduct(name, price, unit, imagePath: selectedImagePath, stockQuantity: stock);
                  } else {
                     final updatedProduct = Product(
                        id: product.id,
                        name: name,
                        price: price,
                        unit: unit,
                        imagePath: selectedImagePath,
                        stockQuantity: stock,
                     );
                     viewModel.updateProduct(updatedProduct);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('商品库管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductViewModel>().loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加商品'),
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, viewModel, child) {
           if (viewModel.isLoading) {
             return const Center(child: CircularProgressIndicator());
           }
           
           if (viewModel.errorMessage != null) {
             return Center(child: Text('Error: ${viewModel.errorMessage}'));
           }
           
           if (viewModel.products.isEmpty) {
             return const Center(child: Text('暂无商品，请点击右下角添加'));
           }

           return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: viewModel.products.length,
             itemBuilder: (context, index) {
               final product = viewModel.products[index];
               return Card(
                 elevation: 0,
                 color: Theme.of(context).colorScheme.surface,
                 margin: const EdgeInsets.only(bottom: 12),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(12),
                   side: BorderSide(
                     color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                   ),
                 ),
                 child: ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   leading: CircleAvatar(
                     backgroundColor: product.imagePath != null ? Colors.transparent : Colors.primaries[product.name.hashCode % Colors.primaries.length].withOpacity(0.2),
                     backgroundImage: product.imagePath != null ? FileImage(File(product.imagePath!)) : null,
                     child: product.imagePath == null 
                       ? Text(
                           product.name.isNotEmpty ? product.name[0] : '?',
                           style: TextStyle(
                             color: Colors.primaries[product.name.hashCode % Colors.primaries.length],
                             fontWeight: FontWeight.bold,
                           ),
                         )
                       : null,
                   ),
                   title: Text(
                     product.name,
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                   subtitle: Row(
                     children: [
                       Text(
                         '¥${product.price} / ${product.unit}',
                         style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                       ),
                       const Gap(12),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: product.stockQuantity > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: product.stockQuantity > 0 ? Colors.green : Colors.red, width: 0.5),
                         ),
                         child: Text(
                           '库存: ${product.stockQuantity}',
                           style: TextStyle(
                             fontSize: 12,
                             color: product.stockQuantity > 0 ? Colors.green[700] : Colors.red[700],
                           ),
                         ),
                       ),
                     ],
                   ),
                   trailing: PopupMenuButton<String>(
                     icon: const Icon(Icons.more_vert),
                     onSelected: (value) {
                       if (value == 'edit') {
                         _showAddEditDialog(context, product: product);
                       } else if (value == 'delete') {
                         _confirmDelete(context, viewModel, product);
                       }
                     },
                     itemBuilder: (context) => [
                       const PopupMenuItem(
                         value: 'edit',
                         child: Row(
                           children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('编辑')],
                         ),
                       ),
                       const PopupMenuItem(
                         value: 'delete',
                         child: Row(
                           children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))],
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
    );
  }

  void _confirmDelete(BuildContext context, ProductViewModel viewModel, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${product.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
