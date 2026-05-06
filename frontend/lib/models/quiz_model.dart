/// Model data untuk Kuis dan Pertanyaan.
/// Semua data diserialisasi ke/dari JSON untuk komunikasi API dan local storage.

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer; // index of correct option
  final int points;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.points = 10,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      points: json['points'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'points': points,
  };
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String createdBy;        // guru ID
  final String createdByName;    // guru name
  final String kelasId;          // team/kelas ID
  final List<QuizQuestion> questions;
  final int durationMinutes;
  final int maxViolations;       // auto-submit threshold
  final bool isSecureMode;       // enable secure exam browser
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
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
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      createdByName: json['createdByName'] ?? '',
      kelasId: json['kelasId']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList() ?? [],
      durationMinutes: json['durationMinutes'] ?? 60,
      maxViolations: json['maxViolations'] ?? 5,
      isSecureMode: json['isSecureMode'] ?? true,
      isActive: json['isActive'] ?? true,
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
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
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };

  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

class QuizSubmission {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final Map<String, int> answers; // questionId -> selectedOption index
  final int score;
  final int totalPoints;
  final int violations;
  final bool autoSubmitted;       // was it auto-submitted due to violations/timer
  final DateTime submittedAt;

  const QuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.answers,
    required this.score,
    required this.totalPoints,
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
      answers: Map<String, int>.from(json['answers'] ?? {}),
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      violations: json['violations'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      submittedAt: DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
