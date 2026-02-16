import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../application/viewmodels/product_view_model.dart';
import '../../domain/entities/product.dart';
import 'package:file_picker/file_picker.dart'; // Ensure file_picker is imported if used, or just dart:io for File
import 'dart:io';

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
    String? selectedImagePath = product?.imagePath;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? '添加商品' : '编辑商品'),
            content: SizedBox(
              width: 500, // Wider for image side-by-side
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                           final path = await context.read<ProductViewModel>().pickImage();
                           if (path != null) {
                             setState(() {
                               selectedImagePath = path;
                             });
                           }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            image: selectedImagePath != null 
                              ? DecorationImage(
                                  image: FileImage(File(selectedImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          ),
                          child: selectedImagePath == null 
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                        ),
                      ),
                      TextButton(
                        onPressed: selectedImagePath == null ? null : () {
                          setState(() {
                            selectedImagePath = null;
                          });
                        },
                        child: const Text('清除图片'),
                      ),
                    ],
                  ),
                  const Gap(24),
                  // Form Section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: '商品名称'),
                          autofocus: true,
                        ),
                        const Gap(10),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: '单价'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const Gap(10),
                        TextField(
                          controller: unitController,
                          decoration: const InputDecoration(labelText: '单位 (如: 个, 箱, 斤)'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  
                  if (name.isEmpty || price < 0 || unit.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('请填写完整的商品信息')),
                     );
                     return;
                  }
    
                  final viewModel = context.read<ProductViewModel>();
                  if (product == null) {
                    viewModel.addProduct(name, price, unit, imagePath: selectedImagePath);
                  } else {
                     final updatedProduct = Product(
                        id: product.id,
                        name: name,
                        price: price,
                        unit: unit,
                        imagePath: selectedImagePath,
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
    return Scaffold(
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
                   subtitle: Text(
                     '¥${product.price} / ${product.unit}',
                     style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
