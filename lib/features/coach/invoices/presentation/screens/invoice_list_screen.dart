import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/invoice.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for invoice list
final invoiceListProvider = FutureProvider<List<Invoice>>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return [];
  }

  return invoiceRepo.getInvoices(user.id);
});

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Invoice',
            onPressed: () {
              context.push('/coach/invoices/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search invoices by number or client...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _statusFilter == 'all',
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Draft',
                        isSelected: _statusFilter == 'draft',
                        onTap: () => setState(() => _statusFilter = 'draft'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sent',
                        isSelected: _statusFilter == 'sent',
                        onTap: () => setState(() => _statusFilter = 'sent'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Paid',
                        isSelected: _statusFilter == 'paid',
                        onTap: () => setState(() => _statusFilter = 'paid'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Overdue',
                        isSelected: _statusFilter == 'overdue',
                        onTap: () => setState(() => _statusFilter = 'overdue'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Invoice list
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                // Filter invoices
                var filteredInvoices = invoices.where((invoice) {
                  // Status filter
                  if (_statusFilter != 'all') {
                    if (_statusFilter != invoice.status.name) {
                      return false;
                    }
                  }
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    return invoice.invoiceNumber
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        invoice.clientId.toLowerCase().contains(_searchQuery);
                  }
                  return true;
                }).toList();

                if (filteredInvoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _statusFilter != 'all'
                              ? 'No invoices found'
                              : 'No invoices yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _statusFilter != 'all'
                              ? 'Try adjusting your filters'
                              : 'Create your first invoice',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                        if (_searchQuery.isEmpty && _statusFilter == 'all') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/coach/invoices/create');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Invoice'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(invoiceListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () {
                          context.push('/coach/invoices/${invoice.id}');
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(invoiceListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/coach/invoices/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${_formatDate(invoice.dueDate)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        invoice.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(invoice.total),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                    if (invoice.status == InvoiceStatus.paid && invoice.paidDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Paid',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(invoice.paidDate!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

