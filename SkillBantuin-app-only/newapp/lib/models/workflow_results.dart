import 'task_models.dart';

class PaymentSubmissionResult {
  final String paymentMethod;
  final String proofFileName;
  final int totalAmount;
  final PaymentStatus paymentStatus;
  final TaskStatus nextTaskStatus;

  const PaymentSubmissionResult({
    required this.paymentMethod,
    required this.proofFileName,
    required this.totalAmount,
    required this.paymentStatus,
    required this.nextTaskStatus,
  });
}

class WorkSubmissionResult {
  final String fileName;
  final String? resultLink;
  final String note;
  final WorkStatus nextWorkStatus;
  final TaskStatus nextTaskStatus;

  const WorkSubmissionResult({
    required this.fileName,
    required this.note,
    required this.nextWorkStatus,
    required this.nextTaskStatus,
    this.resultLink,
  });
}

class ReviewSubmissionResult {
  final int rating;
  final String comment;
  final TaskStatus finalTaskStatus;

  const ReviewSubmissionResult({
    required this.rating,
    required this.comment,
    required this.finalTaskStatus,
  });
}
