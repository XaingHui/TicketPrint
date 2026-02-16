import 'dart:typed_data';
import '../entities/invoice.dart';

/// PDF 生成服务接口
/// 定义生成 PDF 的契约，具体实现（使用 pdf package）在 Data 层
abstract class IPdfGeneratorService {
  /// 根据 Invoice 生成 PDF 文件的二进制数据
  Future<Uint8List> generateInvoicePdf(Invoice invoice, String merchantName, String? merchantPhone, String? merchantAddress);
}
