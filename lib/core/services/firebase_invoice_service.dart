import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';

/// Firebase implementation of InvoiceRepository
class FirebaseInvoiceService implements InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Invoice>> getInvoices(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('coachId', isEqualTo: coachId)
          .orderBy('issueDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Invoice.fromJson({
              'id': doc.id,
              ...data,
              'issueDate': (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'status': data['status']?.toString().split('.').last ?? 'draft',
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get invoices: $e');
    }
  }

  @override
  Future<List<Invoice>> getClientInvoices({
    required String coachId,
    required String clientId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('coachId', isEqualTo: coachId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('issueDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Invoice.fromJson({
              'id': doc.id,
              ...data,
              'issueDate': (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'status': data['status']?.toString().split('.').last ?? 'draft',
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get client invoices: $e');
    }
  }

  @override
  Future<Invoice> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();

      if (!doc.exists) {
        throw Exception('Invoice not found');
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invoice data is null');
      }
      return Invoice.fromJson({
        'id': doc.id,
        ...data,
        'issueDate': (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'status': data['status']?.toString().split('.').last ?? 'draft',
      });
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final docRef = _firestore.collection('invoices').doc();

      final invoiceData = invoice.toJson();
      invoiceData.remove('id');
      invoiceData['issueDate'] = Timestamp.fromDate(invoice.issueDate);
      invoiceData['dueDate'] = Timestamp.fromDate(invoice.dueDate);
      if (invoice.createdAt != null) {
        invoiceData['createdAt'] = Timestamp.fromDate(invoice.createdAt!);
      }
      if (invoice.paidDate != null) {
        invoiceData['paidDate'] = Timestamp.fromDate(invoice.paidDate!);
      }

      await docRef.set({
        ...invoiceData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return invoice.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  @override
  Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData.remove('id');
      invoiceData['issueDate'] = Timestamp.fromDate(invoice.issueDate);
      invoiceData['dueDate'] = Timestamp.fromDate(invoice.dueDate);
      if (invoice.createdAt != null) {
        invoiceData['createdAt'] = Timestamp.fromDate(invoice.createdAt!);
      }
      if (invoice.paidDate != null) {
        invoiceData['paidDate'] = Timestamp.fromDate(invoice.paidDate!);
      }

      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .update(invoiceData);

      return invoice;
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  @override
  Future<MonthlyRevenue> getMonthlyRevenue({
    required String coachId,
    required int year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final startDate = DateTime(year, targetMonth, 1);
      final endDate = DateTime(year, targetMonth + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('invoices')
          .where('coachId', isEqualTo: coachId)
          .where('issueDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final invoices = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Invoice.fromJson({
              'id': doc.id,
              ...data,
              'issueDate': (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'status': data['status']?.toString().split('.').last ?? 'draft',
            });
          })
          .toList();

      final totalRevenue = invoices
          .where((inv) => inv.status == InvoiceStatus.paid)
          .fold<double>(0.0, (sum, inv) => sum + inv.total);

      final paidInvoices = invoices
          .where((inv) => inv.status == InvoiceStatus.paid)
          .length;

      final pendingInvoices = invoices
          .where((inv) =>
              inv.status == InvoiceStatus.sent ||
              inv.status == InvoiceStatus.overdue)
          .length;

      final averageInvoiceValue = invoices.isNotEmpty
          ? totalRevenue / paidInvoices
          : 0.0;

      return MonthlyRevenue(
        year: year,
        month: targetMonth,
        totalRevenue: totalRevenue,
        invoiceCount: invoices.length,
        paidInvoices: paidInvoices,
        pendingInvoices: pendingInvoices,
        averageInvoiceValue: averageInvoiceValue,
      );
    } catch (e) {
      throw Exception('Failed to get monthly revenue: $e');
    }
  }

  @override
  Future<List<MonthlyRevenue>> getUpcomingMonthsRevenue({
    required String coachId,
    int monthsAhead = 3,
  }) async {
    try {
      final now = DateTime.now();
      final results = <MonthlyRevenue>[];

      for (int i = 0; i < monthsAhead; i++) {
        final targetDate = DateTime(now.year, now.month + i, 1);
        final revenue = await getMonthlyRevenue(
          coachId: coachId,
          year: targetDate.year,
          month: targetDate.month,
        );
        results.add(revenue);
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get upcoming months revenue: $e');
    }
  }

  @override
  Stream<List<Invoice>> watchInvoices(String coachId) {
    return _firestore
        .collection('invoices')
        .where('coachId', isEqualTo: coachId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Invoice.fromJson({
                'id': doc.id,
                ...data,
                'issueDate': (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'dueDate': (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'status': data['status']?.toString().split('.').last ?? 'draft',
              });
            })
            .toList());
  }
}

