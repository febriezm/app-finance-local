/// Item produk yang terdeteksi pada struk
class ReceiptItemDraft {
  final String name;
  final int quantity;
  final int unitPrice; // Integer Rupiah
  final int totalPrice; // Integer Rupiah

  const ReceiptItemDraft({
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  ReceiptItemDraft copyWith({
    String? name,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
  }) {
    return ReceiptItemDraft(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
