const db = require('../config/db');

// ─── Quiz Controller ─────────────────────────────────────────────────────────
// Mengelola CRUD kuis dan submission jawaban siswa.
// Collection: 'quizzes' dan 'quiz_submissions'

const quizController = {
  // GET /api/quiz — List quizzes (filter by kelasId or createdBy)
  getAll: async (req, res) => {
    try {
      let queryRef = db.collection('quizzes');

      if (req.query.kelasId) {
        queryRef = queryRef.where('kelasId', '==', req.query.kelasId);
      }
      if (req.query.createdBy) {
        queryRef = queryRef.where('createdBy', '==', req.query.createdBy);
      }

      const snapshot = await queryRef.get();
      let data = [];
      snapshot.forEach(doc => data.push({ _id: doc.id, ...doc.data() }));

      // Sort in memory to avoid Firestore composite index requirement
      data.sort((a, b) => {
        const dateA = a.createdAt ? new Date(a.createdAt) : new Date(0);
        const dateB = b.createdAt ? new Date(b.createdAt) : new Date(0);
        return dateB - dateA;
      });

      res.status(200).json({ data });
    } catch (error) {
      res.status(500).json({ message: 'Error mengambil data kuis', error: error.message });
    }
  },

  // GET /api/quiz/:id — Get quiz detail
  getById: async (req, res) => {
    try {
      const doc = await db.collection('quizzes').doc(req.params.id).get();
      if (!doc.exists) {
        return res.status(404).json({ message: 'Kuis tidak ditemukan' });
      }
      res.status(200).json({ data: { _id: doc.id, ...doc.data() } });
    } catch (error) {
      res.status(500).json({ message: 'Error mengambil detail kuis', error: error.message });
    }
  },

  // POST /api/quiz — Create quiz (Guru only)
  create: async (req, res) => {
    try {
      const quizData = {
        ...req.body,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const docRef = await db.collection('quizzes').add(quizData);
      res.status(201).json({ 
        message: 'Kuis berhasil dibuat',
        data: { _id: docRef.id, ...quizData }
      });
    } catch (error) {
      res.status(500).json({ message: 'Error membuat kuis', error: error.message });
    }
  },

  // PUT /api/quiz/:id — Update quiz (Guru only)
  update: async (req, res) => {
    try {
      const updateData = {
        ...req.body,
        updatedAt: new Date().toISOString(),
      };

      await db.collection('quizzes').doc(req.params.id).update(updateData);
      res.status(200).json({ message: 'Kuis berhasil diupdate' });
    } catch (error) {
      res.status(500).json({ message: 'Error mengupdate kuis', error: error.message });
    }
  },

  // DELETE /api/quiz/:id — Delete quiz (Guru only)
  remove: async (req, res) => {
    try {
      // Delete quiz
      await db.collection('quizzes').doc(req.params.id).delete();
      
      // Also delete related submissions
      const submissions = await db.collection('quiz_submissions')
        .where('quizId', '==', req.params.id)
        .get();
      
      const batch = db.batch();
      submissions.forEach(doc => batch.delete(doc.ref));
      await batch.commit();

      res.status(200).json({ message: 'Kuis dan semua submission berhasil dihapus' });
    } catch (error) {
      res.status(500).json({ message: 'Error menghapus kuis', error: error.message });
    }
  },

  // POST /api/quiz/:id/submit — Submit answers (Siswa)
  submitAnswers: async (req, res) => {
    try {
      const quizId = req.params.id;
      const { answers, violations, autoSubmitted, violationLog } = req.body;
      const userId = req.user?.id || req.user?.uid || req.body.studentId;
      const userName = req.user?.nama || req.body.studentName || 'Unknown';

      // Check if already submitted
      const existingSubmission = await db.collection('quiz_submissions')
        .where('quizId', '==', quizId)
        .where('studentId', '==', userId)
        .get();

      if (!existingSubmission.empty) {
        return res.status(400).json({ message: 'Anda sudah mengerjakan kuis ini' });
      }

      // Get quiz to calculate score
      const quizDoc = await db.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        return res.status(404).json({ message: 'Kuis tidak ditemukan' });
      }

      const quiz = quizDoc.data();
      const questions = quiz.questions || [];
      
      // Calculate score
      let score = 0;
      let totalPoints = 0;
      for (const q of questions) {
        totalPoints += (q.points || 10);
        const studentAnswer = answers[q.id];
        if (studentAnswer !== undefined && studentAnswer === q.correctAnswer) {
          score += (q.points || 10);
        }
      }

      const submissionData = {
        quizId,
        studentId: userId,
        studentName: userName,
        answers: answers || {},
        score,
        totalPoints,
        violations: violations || 0,
        autoSubmitted: autoSubmitted || false,
        violationLog: violationLog || [],
        submittedAt: new Date().toISOString(),
      };

      const docRef = await db.collection('quiz_submissions').add(submissionData);
      
      res.status(201).json({
        message: 'Jawaban berhasil disimpan',
        data: { _id: docRef.id, ...submissionData }
      });
    } catch (error) {
      res.status(500).json({ message: 'Error menyimpan jawaban', error: error.message });
    }
  },

  // GET /api/quiz/:id/submissions — Get all submissions for a quiz
  getSubmissions: async (req, res) => {
    try {
      const snapshot = await db.collection('quiz_submissions')
        .where('quizId', '==', req.params.id)
        .get();

      let data = [];
      snapshot.forEach(doc => data.push({ _id: doc.id, ...doc.data() }));

      // Sort in memory to avoid Firestore composite index requirement
      data.sort((a, b) => {
        const dateA = a.submittedAt ? new Date(a.submittedAt) : new Date(0);
        const dateB = b.submittedAt ? new Date(b.submittedAt) : new Date(0);
        return dateB - dateA;
      });

      res.status(200).json({ data });
    } catch (error) {
      res.status(500).json({ message: 'Error mengambil submissions', error: error.message });
    }
  },

  // GET /api/quiz/:id/check — Check if student has submitted
  checkSubmission: async (req, res) => {
    try {
      const studentId = req.query.studentId || req.user?.id || req.user?.uid;
      
      const snapshot = await db.collection('quiz_submissions')
        .where('quizId', '==', req.params.id)
        .where('studentId', '==', studentId)
        .limit(1)
        .get();

      res.status(200).json({ hasSubmitted: !snapshot.empty });
    } catch (error) {
      res.status(500).json({ message: 'Error checking submission', error: error.message });
    }
  },
};

module.exports = quizController;
