class QuizQuestion {
  final String id;
  final String questionType;
  final String question;
  final List<String> options;
  final List<int> correctAnswers;
  final int points;
  final String? imageUrl;

  const QuizQuestion({
    required this.id,
    this.questionType = 'multipleChoice',
    required this.question,
    required this.options,
    required this.correctAnswers,
    this.points = 10,
    this.imageUrl,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<int> answers = [];
    if (json['correctAnswers'] != null) {
      answers = List<int>.from(json['correctAnswers']);
    } else if (json['correctAnswer'] != null) {
      answers = [json['correctAnswer'] as int];
    }

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      questionType: json['questionType'] ?? 'multipleChoice',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswers: answers,
      points: json['points'] ?? 10,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionType': questionType,
    'question': question,
    'options': options,
    'correctAnswers': correctAnswers,
    'points': points,
    'imageUrl': imageUrl,
  };
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String createdBy;
  final String createdByName;
  final String kelasId;
  final List<QuizQuestion> questions;
  final int durationMinutes;
  final int maxViolations;
  final bool isSecureMode;
  final bool isActive;
  final bool isScheduled;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final String? shareCode;
  final List<String> sharedKelasIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? scheduledAt;
  final DateTime? closedAt;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.createdBy,
    required this.createdByName,
    required this.kelasId,
    required this.questions,
    this.durationMinutes = 60,
    this.maxViolations = 5,
    this.isSecureMode = true,
    this.isActive = true,
    this.isScheduled = false,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.shareCode,
    this.sharedKelasIds = const [],
    this.startTime,
    this.endTime,
    this.scheduledAt,
    this.closedAt,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? 'Umum',
      createdBy: json['createdBy']?.toString() ?? '',
      createdByName: json['createdByName'] ?? 'Guru',
      kelasId: json['kelasId']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList() ?? [],
      durationMinutes: json['durationMinutes'] ?? 60,
      maxViolations: json['maxViolations'] ?? 5,
      isSecureMode: json['isSecureMode'] ?? true,
      isActive: json['isActive'] ?? true,
      isScheduled: json['isScheduled'] ?? false,
      shuffleQuestions: json['shuffleQuestions'] ?? false,
      shuffleOptions: json['shuffleOptions'] ?? false,
      shareCode: json['shareCode'],
      sharedKelasIds: List<String>.from(json['sharedKelasIds'] ?? []),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.tryParse(json['closedAt']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subject': subject,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'kelasId': kelasId,
    'questions': questions.map((q) => q.toJson()).toList(),
    'durationMinutes': durationMinutes,
    'maxViolations': maxViolations,
    'isSecureMode': isSecureMode,
    'isActive': isActive,
    'isScheduled': isScheduled,
    'shuffleQuestions': shuffleQuestions,
    'shuffleOptions': shuffleOptions,
    'shareCode': shareCode,
    'sharedKelasIds': sharedKelasIds,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

class QuizSubmission {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String kelasId;
  final Map<String, dynamic> answers;
  final Map<String, String> essayAnswers;
  final int score;
  final int totalPoints;
  final bool hasEssay;
  final int violations;
  final bool autoSubmitted;
  final DateTime submittedAt;

  const QuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.kelasId = '',
    required this.answers,
    this.essayAnswers = const {},
    required this.score,
    required this.totalPoints,
    this.hasEssay = false,
    this.violations = 0,
    this.autoSubmitted = false,
    required this.submittedAt,
  });

  factory QuizSubmission.fromJson(Map<String, dynamic> json) {
    return QuizSubmission(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'],
      kelasId: json['kelasId']?.toString() ?? '',
      answers: Map<String, dynamic>.from(json['answers'] ?? {}),
      essayAnswers: Map<String, String>.from(json['essayAnswers'] ?? {}),
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      hasEssay: json['hasEssay'] ?? false,
      violations: json['violations'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      submittedAt: DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
