// Member entity: now includes optional join and expiry dates.
class Member {
  int? id;
  String name;
  String contact; // phone/email
  String plan; // Monthly/Quarterly/etc
  int attendance;
  String? joinDate; // ISO yyyy-MM-dd
  String? expiryDate; // ISO yyyy-MM-dd

  Member({
    this.id,
    required this.name,
    required this.contact,
    required this.plan,
    this.attendance = 0,
    this.joinDate,
    this.expiryDate,
  });

  // Map plan -> nominal calendar length (approximate) used for usage depletion logic.
  static const Map<String, int> _planLengthDays = {
    'Monthly': 30,
    'Quarterly': 90,
    'Half-Yearly': 180,
    'Yearly': 365,
  };

  int get planDays => _planLengthDays[plan] ?? 30;

  /// Calendar based expiry check.
  bool get _calendarExpired {
    if (expiryDate == null) return false;
    final d = DateTime.tryParse(expiryDate!);
    if (d == null) return false;
    return DateTime.now().isAfter(d);
  }

  /// Consider membership expired if either calendar date passed OR usage (attendance) exhausted.
  bool get isExpired => _calendarExpired || attendance >= planDays;

  /// Effective remaining days: min(calendar days left, usage days left). Never negative.
  int get daysLeft {
    // Calendar days left (treat <1 day but not expired as 1 to show '1d left').
    int calendarLeft;
    if (expiryDate == null) {
      calendarLeft = planDays; // fallback to planDays if no expiry stored
    } else {
      final d = DateTime.tryParse(expiryDate!);
      if (d == null) {
        calendarLeft = planDays;
      } else {
        final diff = d.difference(DateTime.now()).inDays;
        if (diff < 0) {
          calendarLeft = 0;
        } else if (diff == 0 && !_calendarExpired) {
          calendarLeft = 1; // still some hours left today
        } else {
          calendarLeft = diff;
        }
      }
    }
    final usageLeft =
        planDays - attendance; // if attendance grows, this shrinks.
    final effective = usageLeft < calendarLeft ? usageLeft : calendarLeft;
    return effective < 0 ? 0 : effective;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'contact': contact,
    'plan': plan,
    'attendance': attendance,
    'join_date': joinDate,
    'expiry_date': expiryDate,
  };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
    id: m['id'],
    name: m['name'] ?? '',
    contact: m['contact'] ?? '',
    plan: m['plan'] ?? '',
    attendance: m['attendance'] ?? 0,
    joinDate: m['join_date'],
    expiryDate: m['expiry_date'],
  );
}
