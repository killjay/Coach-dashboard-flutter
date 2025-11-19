import '../models/invoice.dart';

/// Abstract repository interface for invoice management
abstract class InvoiceRepository {
  /// Get all invoices for a coach
  Future<List<Invoice>> getInvoices(String coachId);

  /// Get invoices for a specific client
  Future<List<Invoice>> getClientInvoices({
    required String coachId,
    required String clientId,
  });

  /// Get a single invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId);

  /// Create a new invoice
  Future<Invoice> createInvoice(Invoice invoice);

  /// Update an existing invoice
  Future<Invoice> updateInvoice(Invoice invoice);

  /// Delete an invoice
  Future<void> deleteInvoice(String invoiceId);

  /// Get monthly revenue summary
  Future<MonthlyRevenue> getMonthlyRevenue({
    required String coachId,
    required int year,
    int? month,
  });

  /// Get upcoming months revenue forecast
  Future<List<MonthlyRevenue>> getUpcomingMonthsRevenue({
    required String coachId,
    int monthsAhead = 3,
  });

  /// Watch invoices in real-time
  Stream<List<Invoice>> watchInvoices(String coachId);
}

/// Monthly revenue summary
class MonthlyRevenue {
  final int year;
  final int month;
  final double totalRevenue;
  final int invoiceCount;
  final int paidInvoices;
  final int pendingInvoices;
  final double averageInvoiceValue;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.totalRevenue,
    required this.invoiceCount,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.averageInvoiceValue,
  });
}

