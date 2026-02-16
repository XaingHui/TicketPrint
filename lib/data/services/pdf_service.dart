import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // 实际上 printing 包常用于 fetch 字体，但这里主要用 pdf
import '../../domain/entities/invoice.dart';
import '../../domain/services/pdf_generator_interface.dart';

class PdfService implements IPdfGeneratorService {
  @override
  Future<Uint8List> generateInvoicePdf(Invoice invoice, String merchantName, String? merchantPhone, String? merchantAddress) async {
    final pdf = pw.Document();
    
    // 加载支持中文的字体
    final font = await PdfGoogleFonts.notoSansSCRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 标题 (商户名称)
              pw.Center(
                child: pw.Text(
                  merchantName, 
                  style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),

              // 商户信息 (电话/地址)
              if (merchantPhone != null && merchantPhone.isNotEmpty)
                pw.Center(child: pw.Text('电话: $merchantPhone', style: pw.TextStyle(font: font, fontSize: 12))),
              if (merchantAddress != null && merchantAddress.isNotEmpty)
                pw.Center(child: pw.Text('地址: $merchantAddress', style: pw.TextStyle(font: font, fontSize: 12))),
              
              pw.SizedBox(height: 20),
              
              // 票据信息 (隐藏 ID)
              // pw.Text('票据 ID: ${invoice.id}', style: pw.TextStyle(font: font)), 
              pw.Text('日期: ${invoice.createdAt.toString().split('.')[0]}', style: pw.TextStyle(font: font)),
              
              pw.Divider(),
              
              // 商品列表表头
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('商品名称', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('单价', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('单位', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('数量', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('小计', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                ]
              ),
              pw.Divider(),

              // 商品列表内容
              ...invoice.items.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.productName, style: pw.TextStyle(font: font))),
                      pw.Expanded(flex: 1, child: pw.Text(item.price.toStringAsFixed(2), style: pw.TextStyle(font: font))),
                      pw.Expanded(flex: 1, child: pw.Text(item.unit, style: pw.TextStyle(font: font))),
                      pw.Expanded(flex: 1, child: pw.Text(item.quantity.toStringAsFixed(1), style: pw.TextStyle(font: font))),
                      pw.Expanded(flex: 1, child: pw.Text(item.total.toStringAsFixed(2), style: pw.TextStyle(font: font))),
                    ]
                  )
                );
              }).toList(),
              
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // 总计区域
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                   if (invoice.discountAmount > 0) ...[
                     // 原价 (删除线)
                      pw.Text(
                        '原价: ¥${invoice.totalPrice.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: font, 
                          fontSize: 14, 
                          color: PdfColors.grey700,
                          decoration: pw.TextDecoration.lineThrough,
                        ),
                      ),
                      // 优惠
                      pw.Text(
                        '优惠: -¥${invoice.discountAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.red),
                      ),
                      pw.SizedBox(height: 4),
                   ],
                   
                   // 实收 (大字)
                   pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.end,
                     children: [
                       pw.Text(
                         '实收: ', 
                         style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
                       ),
                       pw.Text(
                         '¥${invoice.finalPrice.toStringAsFixed(2)}',
                         style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                       ),
                     ],
                   ),
                ]
              ),

              if (invoice.targetName != null && invoice.targetName!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Divider(borderStyle: pw.BorderStyle.dotted),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                     pw.Text(
                      '客户: ${invoice.targetName}',
                      style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
