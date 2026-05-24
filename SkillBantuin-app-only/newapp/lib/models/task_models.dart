// ─────────────────────────────────────────────────────────────────────────────
//  task_models.dart — semua model + fromApiJson factories
// ─────────────────────────────────────────────────────────────────────────────

enum TaskStatus {
  open,
  waitingOffer,
  negotiation,
  waitingPayment,
  paymentVerified,
  onProgress,
  submitted,
  completed,
  cancelled,
  overdue,
}

enum OfferStatus { pending, accepted, rejected, countered, withdrawn }

enum WorkStatus {
  notStarted,
  inProgress,
  waitingConfirmation,
  completed,
  overdue,
}

enum PaymentStatus { unpaid, pending, verified, failed, refunded }

enum AssistanceType { onsite, remote, hybrid, online }

// ── Helpers ──────────────────────────────────────────────────────────────────

TaskStatus taskStatusFromApi(String? s) => switch (s) {
      'open'         => TaskStatus.open,
      'in_progress'  => TaskStatus.onProgress,
      'completed'    => TaskStatus.completed,
      'cancelled'    => TaskStatus.cancelled,
      _              => TaskStatus.open,
    };

OfferStatus offerStatusFromApi(String? s) => switch (s) {
      'accepted'  => OfferStatus.accepted,
      'rejected'  => OfferStatus.rejected,
      'withdrawn' => OfferStatus.withdrawn,
      _           => OfferStatus.pending,
    };

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

String _nearestAction(TaskStatus s) => switch (s) {
      TaskStatus.open           => 'Menunggu penawaran masuk',
      TaskStatus.negotiation    => 'Tinjau penawaran yang masuk',
      TaskStatus.waitingPayment => 'Upload bukti pembayaran',
      TaskStatus.onProgress     => 'Cek progres terbaru dari freelancer',
      TaskStatus.submitted      => 'Tinjau hasil yang sudah dikirim',
      TaskStatus.completed      => 'Beri rating dan review',
      _                         => '-',
    };

// ── VolunteerOffer ────────────────────────────────────────────────────────────

class VolunteerOffer {
  final String id;
  final String freelancerName;
  final String freelancerSkill;
  final double rating;
  final int completedTasks;
  final int offeredBudget;
  final String proposedDeadline;
  final String message;
  final OfferStatus status;
  final String? freelancerId;
  final String? workResult;

  const VolunteerOffer({
    required this.id,
    required this.freelancerName,
    required this.freelancerSkill,
    required this.rating,
    required this.completedTasks,
    required this.offeredBudget,
    required this.proposedDeadline,
    required this.message,
    required this.status,
    this.freelancerId,
    this.workResult,
  });

  factory VolunteerOffer.fromApiJson(Map<String, dynamic> json) {
    final fl = json['freelancer'] as Map<String, dynamic>? ?? {};
    final fp = fl['freelancer_profile'] as Map<String, dynamic>? ?? {};
    final skills = (fp['skills'] as List<dynamic>?)?.cast<String>() ?? [];

    return VolunteerOffer(
      id: json['id'].toString(),
      freelancerId: fl['id']?.toString(),
      freelancerName: (fl['name'] ?? 'Freelancer') as String,
      freelancerSkill: skills.isNotEmpty ? skills.first : 'Freelancer',
      rating: (fp['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (fp['completed_jobs'] as int?) ?? 0,
      offeredBudget: ((json['price'] as num?) ?? 0).toInt(),
      proposedDeadline: '${json['duration_days'] ?? 1} hari',
      message: (json['cover_letter'] ?? '') as String,
      status: offerStatusFromApi(json['status'] as String?),
      workResult: json['work_result'] as String?,
    );
  }
}

// ── ClientTask ────────────────────────────────────────────────────────────────

class ClientTask {
  final String id;
  final String title;
  final String category;
  final String description;
  final int initialBudget;
  final int? agreedBudget;
  final String deadlineLabel;
  final String createdAtLabel;
  final TaskStatus status;
  final PaymentStatus paymentStatus;
  final AssistanceType assistanceType;
  final String? location;
  final String? attachmentName;
  final String nearestAction;
  final int progress;
  final String? assignedFreelancer;
  final String? acceptedOfferId;   // ID offer yang diterima — dipakai untuk submit review
  final List<VolunteerOffer> offers;

  const ClientTask({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.initialBudget,
    required this.deadlineLabel,
    required this.createdAtLabel,
    required this.status,
    required this.paymentStatus,
    required this.assistanceType,
    required this.nearestAction,
    required this.progress,
    required this.offers,
    this.agreedBudget,
    this.acceptedOfferId,
    this.location,
    this.attachmentName,
    this.assignedFreelancer,
  });

  factory ClientTask.fromApiJson(Map<String, dynamic> json) {
    final status    = taskStatusFromApi(json['status'] as String?);
    final budgetMin = ((json['budget_min'] as num?) ?? 0).toInt();
    final budgetMax = ((json['budget_max'] as num?) ?? 0).toInt();

    final rawOffers = json['offers'] as List<dynamic>? ?? [];
    final offers = rawOffers
        .map((o) => VolunteerOffer.fromApiJson(o as Map<String, dynamic>))
        .toList();

    final accepted       = offers.where((o) => o.status == OfferStatus.accepted);
    final assignedName   = accepted.isNotEmpty ? accepted.first.freelancerName : null;
    final agreedBudget   = accepted.isNotEmpty ? accepted.first.offeredBudget : null;
    final acceptedOffId  = accepted.isNotEmpty ? accepted.first.id : null;

    // /my-tasks juga include accepted_offer di root untuk performa
    final rawAccepted    = json['accepted_offer'] as Map<String, dynamic>?;
    final finalOfferId   = acceptedOffId ?? rawAccepted?['id']?.toString();

    int progress = switch (status) {
      TaskStatus.completed      => 100,
      TaskStatus.submitted      => 95,
      TaskStatus.onProgress     => 50,
      TaskStatus.waitingPayment => 40,
      TaskStatus.negotiation    => 25,
      TaskStatus.open           => 10,
      _                         => 0,
    };

    return ClientTask(
      id:               json['id'].toString(),
      title:            (json['title'] ?? '') as String,
      category:         (json['category'] ?? 'Umum') as String,
      description:      (json['description'] ?? '') as String,
      initialBudget:    budgetMin,
      agreedBudget:     agreedBudget ?? (budgetMax > 0 ? budgetMax : null),
      deadlineLabel:    _fmtDate(json['deadline'] as String?),
      createdAtLabel:   _fmtDate(json['created_at'] as String?),
      status:           status,
      paymentStatus:    PaymentStatus.unpaid,
      assistanceType:   AssistanceType.online,
      nearestAction:    _nearestAction(status),
      progress:         progress,
      offers:           offers,
      assignedFreelancer: assignedName,
      acceptedOfferId:  finalOfferId,
      location:         null,
      attachmentName:   json['attachment'] as String?,
    );
  }
}

// ── AvailableTask ─────────────────────────────────────────────────────────────

class AvailableTask {
  final String id;
  final String title;
  final String category;
  final String description;
  final int initialBudget;
  final String deadlineLabel;
  final AssistanceType assistanceType;
  final String clientName;
  final String postedLabel;
  final int applicantsCount;
  final String budgetRangeLabel;
  final String location;

  const AvailableTask({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.initialBudget,
    required this.deadlineLabel,
    required this.assistanceType,
    required this.clientName,
    required this.postedLabel,
    required this.applicantsCount,
    required this.budgetRangeLabel,
    required this.location,
  });

  factory AvailableTask.fromApiJson(Map<String, dynamic> json) {
    final budgetMin = ((json['budget_min'] as num?) ?? 0).toInt();
    final budgetMax = ((json['budget_max'] as num?) ?? 0).toInt();
    final client = json['client'] as Map<String, dynamic>? ?? {};

    String budgetLabel;
    if (budgetMin > 0 && budgetMax > 0) {
      budgetLabel = 'Rp${_fmtNum(budgetMin)} - Rp${_fmtNum(budgetMax)}';
    } else if (budgetMin > 0) {
      budgetLabel = 'Rp${_fmtNum(budgetMin)}+';
    } else {
      budgetLabel = 'Negosiasi';
    }

    return AvailableTask(
      id:              json['id'].toString(),
      title:           (json['title'] ?? '') as String,
      category:        (json['category'] ?? 'Umum') as String,
      description:     (json['description'] ?? '') as String,
      initialBudget:   budgetMin,
      deadlineLabel:   _fmtDate(json['deadline'] as String?),
      assistanceType:  AssistanceType.online,
      clientName:      (client['name'] ?? 'Client') as String,
      postedLabel:     _timeAgo(json['created_at'] as String?),
      applicantsCount: (json['offers_count'] as int?) ?? 0,
      budgetRangeLabel: budgetLabel,
      location:        'Online',
    );
  }
}

// ── HelperCategory ────────────────────────────────────────────────────────────

class HelperCategory {
  final String title;
  final String subtitle;

  const HelperCategory({required this.title, required this.subtitle});
}

// ── RecommendedFreelancer ─────────────────────────────────────────────────────

class RecommendedFreelancer {
  final String id;
  final String name;
  final String skill;
  final double rating;
  final String responseTime;
  final int baseRate;
  final String? avatar;

  const RecommendedFreelancer({
    this.id = '',
    required this.name,
    required this.skill,
    required this.rating,
    required this.responseTime,
    required this.baseRate,
    this.avatar,
  });

  factory RecommendedFreelancer.fromApiJson(Map<String, dynamic> json) {
    // GET /freelancers returns FreelancerProfile objects with 'user' relation.
    // JSON root IS the profile; 'user' is nested.
    // GET /freelancers/{id} returns { user:{...}, profile:{...} } — handle both.
    final isProfileRoot = json.containsKey('user_id') || json.containsKey('hourly_rate');
    final user    = (json['user'] as Map<String, dynamic>?) ?? json;
    final profile = isProfileRoot ? json : (json['profile'] as Map<String, dynamic>? ?? {});
    final skills  = (profile['skills'] as List<dynamic>?)?.cast<String>() ?? [];

    return RecommendedFreelancer(
      id:           (user['id'] ?? profile['user_id'])?.toString() ?? '',
      name:         (user['name'] ?? 'Freelancer') as String,
      skill:        skills.isNotEmpty ? skills.first : 'Freelancer',
      rating:       (profile['rating'] as num?)?.toDouble() ?? 0.0,
      responseTime: '< 30 menit',
      baseRate:     ((profile['hourly_rate'] as num?) ?? 0).toInt(),
      avatar:       user['avatar'] as String?,
    );
  }
}

// ── FreelancerApplication ─────────────────────────────────────────────────────

class FreelancerApplication {
  final String id;
  final String taskTitle;
  final String category;
  final int offeredBudget;
  final String proposedDeadline;
  final String note;
  final OfferStatus status;
  final String updatedAtLabel;
  final String? taskId;

  const FreelancerApplication({
    required this.id,
    required this.taskTitle,
    required this.category,
    required this.offeredBudget,
    required this.proposedDeadline,
    required this.note,
    required this.status,
    required this.updatedAtLabel,
    this.taskId,
  });

  factory FreelancerApplication.fromApiJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>? ?? {};
    return FreelancerApplication(
      id:               json['id'].toString(),
      taskId:           json['task_id']?.toString(),
      taskTitle:        (task['title'] ?? 'Proyek') as String,
      category:         (task['category'] ?? 'Umum') as String,
      offeredBudget:    ((json['price'] as num?) ?? 0).toInt(),
      proposedDeadline: '${json['duration_days'] ?? 1} hari',
      note:             (json['cover_letter'] ?? '') as String,
      status:           offerStatusFromApi(json['status'] as String?),
      updatedAtLabel:   _timeAgo(json['updated_at'] as String?),
    );
  }
}

// ── FreelancerWorkItem ────────────────────────────────────────────────────────
// DIUPDATE: tambah workStatus, deadlineType, progressNotes untuk fitur Edit Task

class FreelancerWorkItem {
  final String id;          // offer id
  final String taskId;
  final String taskTitle;
  final String clientName;
  final String deadlineLabel;
  final String deadlineType; // 'days_left' | 'warning'
  final int agreedBudget;
  final int progress;        // 0–100 dari DB (progress_percent)
  final WorkStatus status;
  final String workStatus;   // raw string: 'on_track'|'in_progress'|'revision'|'completed'
  final String nextStep;
  final String? workResult;
  final String? progressNotes;

  const FreelancerWorkItem({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.clientName,
    required this.deadlineLabel,
    required this.deadlineType,
    required this.agreedBudget,
    required this.progress,
    required this.status,
    required this.workStatus,
    required this.nextStep,
    this.workResult,
    this.progressNotes,
  });

  /// Dipakai untuk response dari GET /api/freelancer/progress
  factory FreelancerWorkItem.fromProgressApi(Map<String, dynamic> json) {
    final workStatusStr = (json['work_status'] as String?) ?? 'on_track';
    final workStatus    = _workStatusFromString(workStatusStr);

    return FreelancerWorkItem(
      id:             json['offer_id'].toString(),
      taskId:         json['task_id']?.toString() ?? '',
      taskTitle:      (json['title'] ?? 'Proyek') as String,
      clientName:     (json['client_name'] ?? 'Client') as String,
      deadlineLabel:  (json['deadline_info'] ?? '-') as String,
      deadlineType:   (json['deadline_type'] ?? 'days_left') as String,
      agreedBudget:   ((json['price'] as num?) ?? 0).toInt(),
      progress:       (json['progress_percent'] as int?) ?? 0,
      status:         workStatus,
      workStatus:     workStatusStr,
      nextStep:       _nextStepLabel(workStatus),
      workResult:     json['work_result'] as String?,
      progressNotes:  json['progress_notes'] as String?,
    );
  }

  /// Dipakai untuk response dari endpoint offer lama
  factory FreelancerWorkItem.fromApiJson(Map<String, dynamic> json) {
    final task          = json['task'] as Map<String, dynamic>? ?? {};
    final client        = task['client'] as Map<String, dynamic>? ?? {};
    final workStatusStr = (json['work_status'] as String?) ?? 'on_track';
    final workStatus    = _workStatusFromString(workStatusStr);

    return FreelancerWorkItem(
      id:             json['id'].toString(),
      taskId:         json['task_id']?.toString() ?? '',
      taskTitle:      (task['title'] ?? 'Proyek') as String,
      clientName:     (client['name'] ?? 'Client') as String,
      deadlineLabel:  _fmtDate(task['deadline'] as String?),
      deadlineType:   'days_left',
      agreedBudget:   ((json['price'] as num?) ?? 0).toInt(),
      progress:       (json['progress_percent'] as int?) ?? 0,
      status:         workStatus,
      workStatus:     workStatusStr,
      nextStep:       _nextStepLabel(workStatus),
      workResult:     json['work_result'] as String?,
      progressNotes:  json['progress_notes'] as String?,
    );
  }
}

WorkStatus _workStatusFromString(String s) => switch (s) {
      'on_track'    => WorkStatus.inProgress,
      'in_progress' => WorkStatus.inProgress,
      'revision'    => WorkStatus.waitingConfirmation,
      'completed'   => WorkStatus.completed,
      _             => WorkStatus.notStarted,
    };

String _nextStepLabel(WorkStatus s) => switch (s) {
      WorkStatus.notStarted          => 'Mulai pengerjaan setelah brief diterima.',
      WorkStatus.inProgress          => 'Lanjutkan pengerjaan dan kirim progres.',
      WorkStatus.waitingConfirmation => 'Menunggu konfirmasi dari client.',
      WorkStatus.completed           => 'Tugas selesai.',
      _                              => '-',
    };

// ── EarningTransaction ────────────────────────────────────────────────────────

class EarningTransaction {
  final String id;
  final String title;
  final int amount;
  final PaymentStatus status;
  final String dateLabel;

  const EarningTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.status,
    required this.dateLabel,
  });

  factory EarningTransaction.fromApiJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>? ?? {};
    return EarningTransaction(
      id:        json['id'].toString(),
      title:     (task['title'] ?? 'Proyek') as String,
      amount:    ((json['price'] as num?) ?? 0).toInt(),
      status:    PaymentStatus.pending,
      dateLabel: _fmtDate(json['updated_at'] as String?),
    );
  }
}

// ── Private utils ─────────────────────────────────────────────────────────────

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}jt';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}rb';
  return n.toString();
}

String _timeAgo(String? raw) {
  if (raw == null) return 'Baru';
  try {
    final d    = DateTime.parse(raw);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays == 1)    return 'Kemarin';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
    return _fmtDate(raw);
  } catch (_) {
    return 'Baru';
  }
}