import 'package:flutter/material.dart';
import 'member.dart';
import 'db.dart';
import 'member_detail_page.dart';

// Membership plans
const kPlans = ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'];

class MemberListPage extends StatefulWidget {
  const MemberListPage({super.key});
  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  final db = DBService();
  bool loading = true;
  List<Member> members = [];
  List<Member> filtered = [];
  String _query = '';
  int expiringSoonDays = 7;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    members = await db.fetchMembers();
    // Load setting once
    if (!_settingsLoaded) {
      final s = await db.getSetting('expiringSoonDays');
      if (s != null) {
        final v = int.tryParse(s);
        if (v != null && v > 0 && v < 1000) {
          expiringSoonDays = v;
        }
      }
      _settingsLoaded = true;
    }
    _applyFilter();
    setState(() => loading = false);
  }

  void _applyFilter() {
    filtered = members.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.contact.toLowerCase().contains(q) ||
          m.plan.toLowerCase().contains(q);
    }).toList();
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _addMemberDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String contact = '';
    String plan = kPlans.first;
    DateTime joinDate = DateTime.now();
    DateTime expiryDate = _calcExpiry(joinDate, plan);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Member'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: _req,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contact'),
                    validator: _req,
                    onSaved: (v) => contact = v!.trim(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Plan'),
                    value: plan,
                    items: kPlans
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      plan = v!;
                      expiryDate = _calcExpiry(joinDate, plan);
                      setLocal(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Join:'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: joinDate,
                          );
                          if (picked != null) {
                            joinDate = picked;
                            expiryDate = _calcExpiry(joinDate, plan);
                            setLocal(() {});
                          }
                        },
                        child: Text(_fmt(joinDate)),
                      ),
                      const SizedBox(width: 12),
                      const Text('Expiry:'),
                      TextButton(
                        onPressed: () {},
                        child: Text(_fmt(expiryDate)),
                      ),
                    ],
                  ),
                ],
              ),
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
                  await db.insertMember(
                    Member(
                      name: name,
                      contact: contact,
                      plan: plan,
                      joinDate: _fmt(joinDate),
                      expiryDate: _fmt(expiryDate),
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
      ),
    );
  }

  Future<void> _editMemberDialog(Member m) async {
    final formKey = GlobalKey<FormState>();
    String name = m.name;
    String contact = m.contact;
    String plan = m.plan.isNotEmpty ? m.plan : kPlans.first;
    DateTime joinDate = m.joinDate != null
        ? DateTime.parse(m.joinDate!)
        : DateTime.now();
    DateTime expiryDate = m.expiryDate != null
        ? DateTime.parse(m.expiryDate!)
        : _calcExpiry(joinDate, plan);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit Member'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: _req,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  TextFormField(
                    initialValue: contact,
                    decoration: const InputDecoration(labelText: 'Contact'),
                    validator: _req,
                    onSaved: (v) => contact = v!.trim(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: plan,
                    decoration: const InputDecoration(labelText: 'Plan'),
                    items: kPlans
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      plan = v!;
                      expiryDate = _calcExpiry(joinDate, plan);
                      setLocal(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Join:'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: joinDate,
                          );
                          if (picked != null) {
                            joinDate = picked;
                            expiryDate = _calcExpiry(joinDate, plan);
                            setLocal(() {});
                          }
                        },
                        child: Text(_fmt(joinDate)),
                      ),
                      const SizedBox(width: 12),
                      const Text('Expiry:'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: expiryDate,
                          );
                          if (picked != null) {
                            expiryDate = picked;
                            setLocal(() {});
                          }
                        },
                        child: Text(_fmt(expiryDate)),
                      ),
                    ],
                  ),
                ],
              ),
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
                  await db.updateMember(
                    Member(
                      id: m.id,
                      name: name,
                      contact: contact,
                      plan: plan,
                      attendance: m.attendance,
                      joinDate: _fmt(joinDate),
                      expiryDate: _fmt(expiryDate),
                    ),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _incrementAttendance(Member m) async {
    await db.updateMember(
      Member(
        id: m.id,
        name: m.name,
        contact: m.contact,
        plan: m.plan,
        attendance: m.attendance + 1,
        joinDate: m.joinDate,
        expiryDate: m.expiryDate,
      ),
    );
    _load();
  }

  Future<void> _delete(Member m) async {
    await db.deleteMember(m.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final expired = members.where((m) => m.isExpired).length;
    final expiringSoon = members.where((m) {
      if (m.isExpired) return false;
      final days = m.daysLeft; // already accounts for usage + calendar
      return days > 0 && days <= expiringSoonDays;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search name, contact, plan',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _query = v.trim();
                        _applyFilter();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _statBox('Total', total.toString(), Colors.blue),
                      const SizedBox(width: 6),
                      _statBox('Expired', expired.toString(), Colors.red),
                      const SizedBox(width: 6),
                      _statBox('Soon', expiringSoon.toString(), Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No members'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            Color? cardColor;
                            if (m.isExpired) {
                              cardColor = Colors.red.withOpacity(.10);
                            } else if (m.daysLeft > 0 &&
                                m.daysLeft <= expiringSoonDays) {
                              cardColor = Colors.orange.withOpacity(.10);
                            }
                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MemberDetailPage(member: m),
                                  ),
                                ).then((_) => _load()),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    m.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                if (m.isExpired)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.red.shade600,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'EXPIRED',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  )
                                                else if (m.daysLeft > 0 &&
                                                    m.daysLeft <=
                                                        expiringSoonDays)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange
                                                          .shade700,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${m.daysLeft}d',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(_memberSubtitle(m)),
                                            const SizedBox(height: 6),
                                            _progressBar(m),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _editMemberDialog(m);
                                          if (v == 'att')
                                            _incrementAttendance(m);
                                          if (v == 'renew') _promptRenew(m);
                                          if (v == 'del') _delete(m);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'att',
                                            child: Text('Add Attendance'),
                                          ),
                                          if (m.isExpired)
                                            const PopupMenuItem(
                                              value: 'renew',
                                              child: Text('Renew'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'del',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemberDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _memberSubtitle(Member m) {
    // Calendar remaining (raw) for info
    int? calendarLeft;
    if (m.expiryDate != null) {
      final d = DateTime.tryParse(m.expiryDate!);
      if (d != null) {
        final diff = d.difference(DateTime.now()).inDays;
        calendarLeft = diff < 0 ? 0 : diff;
      }
    }
    final usageLeft = m.planDays - m.attendance;
    final effective = m.daysLeft;
    final parts = <String>[m.plan, 'Att:${m.attendance}/${m.planDays}'];
    if (m.isExpired) {
      parts.add('Expired');
    } else {
      parts.add('Eff:${effective}d');
      if (calendarLeft != null) parts.add('Cal:${calendarLeft}d');
      parts.add('Use:${usageLeft < 0 ? 0 : usageLeft}d');
    }
    return parts.join(' | ');
  }

  Widget _progressBar(Member m) {
    final used = m.attendance;
    final total = m.planDays;
    final pct = (used / total).clamp(0, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.toDouble(),
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(.2),
            color: m.isExpired
                ? Colors.red
                : (pct >= 0.8 ? Colors.orange : Colors.green),
          ),
        ),
        const SizedBox(height: 2),
        Text('${used}/${total} sessions', style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Future<void> _promptRenew(Member m) async {
    final now = DateTime.now();
    String newPlan = m.plan; // allow changing plan at renewal
    DateTime newJoin = now;
    DateTime newExpiry = _calcExpiry(newJoin, newPlan);
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Renew ${m.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: newPlan,
                decoration: const InputDecoration(labelText: 'Plan'),
                items: kPlans
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  newPlan = v!;
                  newExpiry = _calcExpiry(newJoin, newPlan);
                  setLocal(() {});
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Start:'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: newJoin,
                      );
                      if (picked != null) {
                        newJoin = picked;
                        newExpiry = _calcExpiry(newJoin, newPlan);
                        setLocal(() {});
                      }
                    },
                    child: Text(_fmt(newJoin)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Expiry:'),
                  TextButton(onPressed: () {}, child: Text(_fmt(newExpiry))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () async {
                await db.updateMember(
                  Member(
                    id: m.id,
                    name: m.name,
                    contact: m.contact,
                    plan: newPlan,
                    attendance: 0, // reset usage
                    joinDate: _fmt(newJoin),
                    expiryDate: _fmt(newExpiry),
                  ),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              },
              child: const Text('RENEW'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final controller = TextEditingController(text: expiringSoonDays.toString());
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Expiring Soon Threshold (days)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v > 0 && v < 1000) {
                expiringSoonDays = v;
                await db.setSetting('expiringSoonDays', v.toString());
                _applyFilter();
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontSize: 16,
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

  DateTime _calcExpiry(DateTime join, String plan) {
    switch (plan) {
      case 'Monthly':
        return DateTime(join.year, join.month + 1, join.day);
      case 'Quarterly':
        return DateTime(join.year, join.month + 3, join.day);
      case 'Half-Yearly':
        return DateTime(join.year, join.month + 6, join.day);
      case 'Yearly':
        return DateTime(join.year + 1, join.month, join.day);
      default:
        return join.add(const Duration(days: 30));
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
