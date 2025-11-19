import 'package:flutter/material.dart';
import '../../../../../core/models/invoice.dart';

class InvoiceItemFormTile extends StatefulWidget {
  final InvoiceItem item;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onDelete;

  const InvoiceItemFormTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<InvoiceItemFormTile> createState() => _InvoiceItemFormTileState();
}

class _InvoiceItemFormTileState extends State<InvoiceItemFormTile> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toString());
    _descriptionController.addListener(_onChanged);
    _quantityController.addListener(_onChanged);
    _unitPriceController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final total = quantity * unitPrice;

    widget.onChanged(
      widget.item.copyWith(
        description: _descriptionController.text,
        quantity: quantity,
        unitPrice: unitPrice,
        total: total,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price *',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Total',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '\$${widget.item.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

