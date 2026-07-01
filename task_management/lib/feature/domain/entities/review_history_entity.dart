import 'enums.dart';

class ReviewHistoryEntity {
  final String id;
  final String taskId;
  final String reviewerId;
  final ReviewResult result;
  final String? comment;
  final DateTime createdAt;

  const ReviewHistoryEntity({
    required this.id,
    required this.taskId,
    required this.reviewerId,
    required this.result,
    this.comment,
    required this.createdAt,
  });

  ReviewHistoryEntity copyWith({
    String? id,
    String? taskId,
    String? reviewerId,
    ReviewResult? result,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewHistoryEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      reviewerId: reviewerId ?? this.reviewerId,
      result: result ?? this.result,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHistoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ReviewHistoryEntity(id: $id, taskId: $taskId, result: $result)';
}
