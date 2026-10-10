class ReviewReply {
  const ReviewReply({required this.text, required this.createdAt});

  final String text;
  final DateTime createdAt;
}

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

  final int rating;

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
