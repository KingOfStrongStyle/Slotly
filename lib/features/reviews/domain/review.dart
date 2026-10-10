/// Owner's public answer to a review.
class ReviewReply {
  const ReviewReply({required this.text, required this.createdAt});

  final String text;
  final DateTime createdAt;
}

/// Customer feedback about one completed booking.
///
/// A review always belongs to a booking, so a customer can rate a business
/// only after a real visit and only once per visit.
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.organizationId,
    required this.serviceId,
    required this.serviceTitle,
    required this.specialistId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.reply,
  });

  static const minRating = 1;
  static const maxRating = 5;
  static const maxTextLength = 1000;

  final String id;
  final String bookingId;
  final String organizationId;
  final String serviceId;
  final String serviceTitle;
  final String specialistId;
  final String authorId;
  final String authorName;

  /// 1…5 stars.
  final int rating;

  /// Empty when the customer left only stars.
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ReviewReply? reply;

  Review copyWith({
    int? rating,
    String? text,
    DateTime? updatedAt,
    ReviewReply? reply,
  }) => Review(
    id: id,
    bookingId: bookingId,
    organizationId: organizationId,
    serviceId: serviceId,
    serviceTitle: serviceTitle,
    specialistId: specialistId,
    authorId: authorId,
    authorName: authorName,
    rating: rating ?? this.rating,
    text: text ?? this.text,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    reply: reply ?? this.reply,
  );

  @override
  String toString() => 'Review($id, $rating★, booking $bookingId)';
}
