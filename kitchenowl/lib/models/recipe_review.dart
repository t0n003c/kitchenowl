import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/user.dart';

class RecipeReview extends Model {
  final int? id;
  final int rating;
  final String review;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecipeReview({
    this.id,
    required this.rating,
    this.review = '',
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory RecipeReview.fromJson(Map<String, dynamic> map) {
    DateTime? timestamp(dynamic value) => value is int
        ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
        : value is String
            ? DateTime.tryParse(value)
            : null;

    return RecipeReview(
      id: map['id'],
      rating: map['rating'] ?? 0,
      review: map['review'] ?? '',
      user: map['user'] is Map<String, dynamic>
          ? User.fromJson(map['user'])
          : null,
      createdAt: timestamp(map['created_at']),
      updatedAt: timestamp(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, rating, review, user, createdAt, updatedAt];

  @override
  Map<String, dynamic> toJson() => {
        'rating': rating,
        'review': review,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()..['id'] = id;
}
