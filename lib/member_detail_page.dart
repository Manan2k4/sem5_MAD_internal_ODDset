import 'package:flutter/material.dart';
import 'member.dart';
import 'fee.dart';
import 'db.dart';
// MemberDetailPage: shows fees of a member, allows add fee, mark paid, delete.

class MemberDetailPage extends StatefulWidget {
  final Member member;
  const MemberDetailPage({super.key, required this.member});
  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  final db = DBService();
  List<Fee> fees = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    fees = await db.feesFor(widget.member.id!);
    setState(() => loading = false);
  }

  Future<void> _addFeeDialog() async {
    final formKey = GlobalKey<FormState>();
    String amountStr = '';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Fee'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: _rq,
                onSaved: (v) => amountStr = v!.trim(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Due:'),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: dueDate,
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                    child: Text(_fmt(dueDate)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                await db.insertFee(
                  Fee(
                    memberId: widget.member.id!,
                    amount: double.tryParse(amountStr) ?? 0,
                    dueDate: _fmt(dueDate),
                    status: 'Unpaid',
                  ),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  String? _rq(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  Future<void> _markPaid(Fee f) async {
    await db.markPaid(f);
    _load();
  }

  Future<void> _delete(Fee f) async {
    await db.deleteFee(f.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final total = fees.fold<double>(0, (p, e) => p + e.amount);
    final unpaid = fees
        .where((f) => f.status != 'Paid')
        .fold<double>(0, (p, e) => p + e.amount);
    final paidCount = fees.where((f) => f.status == 'Paid').length;
    return Scaffold(
      appBar: AppBar(title: Text(m.name)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan: ${m.plan}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Contact: ${m.contact}'),
                          Text('Attendance: ${m.attendance}'),
                          if (m.joinDate != null) Text('Joined: ${m.joinDate}'),
                          if (m.expiryDate != null)
                            Text(
                              'Expiry: ${m.expiryDate}${m.isExpired ? ' (Expired)' : ''}',
                            ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: _addFeeDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Fee'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _miniStat(
                        'Total',
                        '₹${total.toStringAsFixed(0)}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      _miniStat(
                        'Unpaid',
                        '₹${unpaid.toStringAsFixed(0)}',
                        Colors.red,
                      ),
                      const SizedBox(width: 6),
                      _miniStat('Paid', '$paidCount', Colors.green),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: fees.isEmpty
                      ? const Center(child: Text('No fees yet'))
                      : ListView.builder(
                          itemCount: fees.length,
                          itemBuilder: (_, i) {
                            final f = fees[i];
                            final paid = f.status == 'Paid';
                            return ListTile(
                              title: Text(
                                '₹${f.amount.toStringAsFixed(2)} • ${f.status}',
                                style: TextStyle(
                                  color: paid ? Colors.green : Colors.red,
                                ),
                              ),
                              subtitle: Text(
                                'Due: ${f.dueDate}${paid && f.paymentDate != null ? '\nPaid: ${f.paymentDate!.substring(0, 10)}' : ''}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'pay') _markPaid(f);
                                  if (v == 'del') _delete(f);
                                },
                                itemBuilder: (_) => [
                                  if (!paid)
                                    const PopupMenuItem(
                                      value: 'pay',
                                      child: Text('Mark Paid'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'del',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget _miniStat(String label, String value, Color color) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withOpacity(.8)),
        ),
      ],
    ),
  ),
);
