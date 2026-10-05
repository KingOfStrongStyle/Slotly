class TimeSlot {
  const TimeSlot({required this.startAt, required this.isAvailable});

  final DateTime startAt;
  final bool isAvailable;

  @override
  bool operator ==(Object other) =>
      other is TimeSlot &&
      other.startAt == startAt &&
      other.isAvailable == isAvailable;

  @override
  int get hashCode => Object.hash(startAt, isAvailable);

  @override
  String toString() => 'TimeSlot($startAt, available: $isAvailable)';
}
