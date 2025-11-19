import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

/// Invoice status enum
@JsonEnum()
enum InvoiceStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('sent')
  sent,
  @JsonValue('paid')
  paid,
  @JsonValue('overdue')
  overdue,
  @JsonValue('cancelled')
  cancelled,
}

/// Invoice model
@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String coachId,
    required String clientId,
    required String invoiceNumber,
    required DateTime issueDate,
    required DateTime dueDate,
    required double subtotal,
    required double tax,
    required double total,
    required String currency, // 'USD', 'EUR', etc.
    required InvoiceStatus status,
    String? description,
    String? notes,
    List<InvoiceItem>? items,
    DateTime? paidDate,
    String? paymentMethod,
    DateTime? createdAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

/// Invoice item model
@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String description,
    required int quantity,
    required double unitPrice,
    required double total,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}

