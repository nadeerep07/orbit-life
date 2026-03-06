void main() {
  final fields = <int, dynamic>{
    0: 'id123',
    1: 'title',
    2: 'provider',
    3: 1000.0,
    4: null,
    5: 12,
    6: 0,
    7: DateTime.now(),
    8: '',
    9: null,
    10: null,
    11: null,
    12: null,
  };

  try {
    bool isReminderEnabled = fields[12] == null ? false : fields[12] as bool;
    print('isReminderEnabled evaluated to: $isReminderEnabled');
  } catch (e, st) {
    print('Error: $e\n$st');
  }
}
