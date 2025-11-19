import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/invoice.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../core/repositories/client_repository.dart';
import '../../../clients/presentation/screens/client_list_screen.dart' show clientListProvider;
import 'invoice_list_screen.dart' show invoiceListProvider;
import '../widgets/invoice_item_form_tile.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? invoice; // If provided, we're editing
  final String? clientId; // Pre-select a client

  const CreateInvoiceScreen({
    super.key,
    this.invoice,
    this.clientId,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _selectedClientId = '';
  String _currency = 'USD';
  InvoiceStatus _status = InvoiceStatus.draft;
  double _taxRate = 0.0;
  List<InvoiceItem> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _descriptionController.text = widget.invoice!.description ?? '';
      _notesController.text = widget.invoice!.notes ?? '';
      _issueDate = widget.invoice!.issueDate;
      _dueDate = widget.invoice!.dueDate;
      _selectedClientId = widget.invoice!.clientId;
      _currency = widget.invoice!.currency;
      _status = widget.invoice!.status;
      _taxRate = (widget.invoice!.tax / widget.invoice!.subtotal * 100);
      _items = List.from(widget.invoice!.items ?? []);
    } else if (widget.clientId != null) {
      _selectedClientId = widget.clientId!;
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  double get _tax {
    return _subtotal * (_taxRate / 100);
  }

  double get _total {
    return _subtotal + _tax;
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isIssueDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one invoice item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final invoiceRepo = ref.read(invoiceRepositoryProvider);

      final invoice = Invoice(
        id: widget.invoice?.id ?? const Uuid().v4(),
        coachId: user.id,
        clientId: _selectedClientId,
        invoiceNumber: _invoiceNumberController.text.trim(),
        issueDate: _issueDate,
        dueDate: _dueDate,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
        currency: _currency,
        status: _status,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: _items,
        createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      );

      if (widget.invoice != null) {
        await invoiceRepo.updateInvoice(invoice);
      } else {
        await invoiceRepo.createInvoice(invoice);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoice != null
                  ? 'Invoice updated successfully'
                  : 'Invoice created successfully',
            ),
          ),
        );
        ref.invalidate(invoiceListProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          id: const Uuid().v4(),
          description: '',
          quantity: 1,
          unitPrice: 0.0,
          total: 0.0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, InvoiceItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice != null ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveInvoice,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client Selection
            clientsAsync.when(
              data: (clients) => DropdownButtonFormField<String>(
                value: _selectedClientId.isEmpty ? null : _selectedClientId,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: clients.map((client) {
                  return DropdownMenuItem(
                    value: client.id,
                    child: Text('${client.name} (${client.email})'),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a client';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedClientId = value);
                  }
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading clients'),
            ),
            const SizedBox(height: 16),
            // Invoice Number
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'Invoice Number *',
                hintText: 'e.g., INV-2024-001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter invoice number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Issue Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_issueDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_dueDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Currency and Tax Rate
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _currency = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _taxRate.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Tax Rate (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _taxRate = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status
            DropdownButtonFormField<InvoiceStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: InvoiceStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Invoice Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${_items.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            if (_items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add items to create your invoice',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(
                _items.length,
                (index) => InvoiceItemFormTile(
                  item: _items[index],
                  onChanged: (item) => _updateItem(index, item),
                  onDelete: () => _removeItem(index),
                ),
              ),
            const SizedBox(height: 24),
            // Summary Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: _subtotal),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Tax', value: _tax),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total',
                      value: _total,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional notes for the invoice',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveInvoice,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Invoice'),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.blue : null,
              ),
        ),
      ],
    );
  }
}

