// Fee record for a member: amount, due date, status (Paid/Unpaid), optional payment date.
class Fee {
  int? id;
  int memberId;
  double amount;
  String dueDate;
  String status; // Paid / Unpaid
  String? paymentDate;
  Fee({
    this.id,
    required this.memberId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentDate,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'memberId': memberId,
    'amount': amount,
    'dueDate': dueDate,
    'status': status,
    'paymentDate': paymentDate,
  };
  factory Fee.fromMap(Map<String, dynamic> m) => Fee(
    id: m['id'],
    memberId: m['memberId'],
    amount: (m['amount'] is int)
        ? (m['amount'] as int).toDouble()
        : m['amount'],
    dueDate: m['dueDate'],
    status: m['status'],
    paymentDate: m['paymentDate'],
  );
}
