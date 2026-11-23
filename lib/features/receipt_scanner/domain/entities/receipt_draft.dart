import 'dart:typed_data';
import 'receipt_item_draft.dart';

/// Draft transaksi hasil ekstraksi struk belanja.
/// Menampung nilai yang berhasil diparsing beserta tingkat keyakinan (certainty/confidence).
class ReceiptDraft {
  final String? merchant;
  final DateTime? occurredAt;
  final int? totalAmount; // Nominal Rupiah integer
  final int? subtotal;
  final int? taxAmount; // PPN / PB1
  final int? serviceCharge;
  final int? discountAmount;
  final List<ReceiptItemDraft> items;

  // Indikator kepastian (Blueprint 4.5: indikasi field yang belum pasti)
  final bool isMerchantCertain;
  final bool isDateCertain;
  final bool isTotalCertain;

  final String? suggestedCategoryId;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String rawText;

  const ReceiptDraft({
    this.merchant,
    this.occurredAt,
    this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.serviceCharge,
    this.discountAmount,
    this.items = const [],
    this.isMerchantCertain = true,
    this.isDateCertain = true,
    this.isTotalCertain = true,
    this.suggestedCategoryId,
    this.imagePath,
    this.imageBytes,
    required this.rawText,
  });

  bool get hasItems => items.isNotEmpty;

  ReceiptDraft copyWith({
    String? merchant,
    DateTime? occurredAt,
    int? totalAmount,
    int? subtotal,
    int? taxAmount,
    int? serviceCharge,
    int? discountAmount,
    List<ReceiptItemDraft>? items,
    bool? isMerchantCertain,
    bool? isDateCertain,
    bool? isTotalCertain,
    String? suggestedCategoryId,
    String? imagePath,
    Uint8List? imageBytes,
    String? rawText,
  }) {
    return ReceiptDraft(
      merchant: merchant ?? this.merchant,
      occurredAt: occurredAt ?? this.occurredAt,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      discountAmount: discountAmount ?? this.discountAmount,
      items: items ?? this.items,
      isMerchantCertain: isMerchantCertain ?? this.isMerchantCertain,
      isDateCertain: isDateCertain ?? this.isDateCertain,
      isTotalCertain: isTotalCertain ?? this.isTotalCertain,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      rawText: rawText ?? this.rawText,
    );
  }
}
