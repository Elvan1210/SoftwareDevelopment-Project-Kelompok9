const db = require('../config/db');
const crypto = require('crypto');

const quizController = {
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

      if (req.query.kelasId) {
        const sharedSnapshot = await db.collection('quizzes')
          .where('sharedKelasIds', 'array-contains', req.query.kelasId)
          .get();
        sharedSnapshot.forEach(doc => {
          if (!data.find(d => d._id === doc.id)) {
            data.push({ _id: doc.id, ...doc.data() });
          }
        });
      }

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

  create: async (req, res) => {
    try {
      const shareCode = crypto.randomBytes(4).toString('hex').toUpperCase();
      const quizData = {
        ...req.body,
        shareCode,
        sharedKelasIds: req.body.sharedKelasIds || [],
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

  remove: async (req, res) => {
    try {
      await db.collection('quizzes').doc(req.params.id).delete();

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

  shareToKelas: async (req, res) => {
    try {
      const { kelasIds } = req.body;
      const quizDoc = await db.collection('quizzes').doc(req.params.id).get();
      if (!quizDoc.exists) {
        return res.status(404).json({ message: 'Kuis tidak ditemukan' });
      }

      const existing = quizDoc.data().sharedKelasIds || [];
      const merged = [...new Set([...existing, ...kelasIds])];

      await db.collection('quizzes').doc(req.params.id).update({
        sharedKelasIds: merged,
        updatedAt: new Date().toISOString(),
      });

      res.status(200).json({
        message: 'Kuis berhasil di-share',
        shareCode: quizDoc.data().shareCode,
        sharedKelasIds: merged,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error sharing kuis', error: error.message });
    }
  },

  joinByCode: async (req, res) => {
    try {
      const { shareCode } = req.params;
      const snapshot = await db.collection('quizzes')
        .where('shareCode', '==', shareCode)
        .limit(1)
        .get();

      if (snapshot.empty) {
        return res.status(404).json({ message: 'Kode kuis tidak ditemukan' });
      }

      const doc = snapshot.docs[0];
      res.status(200).json({ data: { _id: doc.id, ...doc.data() } });
    } catch (error) {
      res.status(500).json({ message: 'Error join kuis', error: error.message });
    }
  },

  submitAnswers: async (req, res) => {
    try {
      const quizId = req.params.id;
      const { answers, violations, autoSubmitted, violationLog, kelasId, essayAnswers } = req.body;
      const userId = req.user?.id || req.user?.uid || req.body.studentId;
      let userName = req.user?.nama || req.body.studentName || 'Unknown';
      let userEmail = req.user?.email || '';

      if (userName === 'Unknown' && userId) {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          const udata = userDoc.data();
          userName = udata.nama || 'Unknown';
          userEmail = udata.email || userEmail;
        }
      }

      const existingSubmission = await db.collection('quiz_submissions')
        .where('quizId', '==', quizId)
        .where('studentId', '==', userId)
        .get();

      if (!existingSubmission.empty) {
        return res.status(400).json({ message: 'Anda sudah mengerjakan kuis ini' });
      }

      const quizDoc = await db.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        return res.status(404).json({ message: 'Kuis tidak ditemukan' });
      }

      const quiz = quizDoc.data();
      const questions = quiz.questions || [];

      let score = 0;
      let totalPoints = 0;
      let hasEssay = false;

      for (const q of questions) {
        const pts = q.points || 10;
        totalPoints += pts;
        const qType = q.questionType || 'multipleChoice';

        if (qType === 'essay') {
          hasEssay = true;
          continue;
        }

        if (qType === 'multipleChoice') {
          const studentAnswer = answers ? answers[q.id] : undefined;
          const correct = q.correctAnswers ? q.correctAnswers[0] : q.correctAnswer;
          if (studentAnswer !== undefined && studentAnswer === correct) {
            score += pts;
          }
        }

        if (qType === 'multipleAnswer') {
          const studentAnswer = answers ? answers[q.id] : undefined;
          const correctAnswers = q.correctAnswers || [];
          if (studentAnswer !== undefined && correctAnswers.includes(studentAnswer)) {
            score += pts;
          }
        }

        if (qType === 'complexCheckbox') {
          const studentAnswers = answers ? answers[q.id] : undefined;
          const correctAnswers = q.correctAnswers || [];
          if (Array.isArray(studentAnswers) && Array.isArray(correctAnswers)) {
            // Ensure both are arrays of strings/numbers before sorting to prevent weird type crashes
            const sortedStudent = studentAnswers.map(String).sort();
            const sortedCorrect = correctAnswers.map(String).sort();
            if (sortedStudent.length === sortedCorrect.length &&
                sortedStudent.every((v, i) => v === sortedCorrect[i])) {
              score += pts;
            }
          }
        }
      }

      const submissionData = {
        quizId,
        studentId: userId,
        studentName: userName,
        studentEmail: userEmail,
        kelasId: kelasId || '',
        answers: answers || {},
        essayAnswers: essayAnswers || {},
        score,
        totalPoints,
        hasEssay,
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

  getSubmissions: async (req, res) => {
    try {
      let queryRef = db.collection('quiz_submissions')
        .where('quizId', '==', req.params.id);

      if (req.query.kelasId) {
        queryRef = queryRef.where('kelasId', '==', req.query.kelasId);
      }

      const snapshot = await queryRef.get();

      let data = [];
      snapshot.forEach(doc => data.push({ _id: doc.id, ...doc.data() }));

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

  reportLiveViolation: async (req, res) => {
    try {
      const quizId = req.params.id;
      const { reason } = req.body;
      const userId = req.user?.id || req.user?.uid;
      let userName = req.user?.nama || 'Unknown';

      if (userName === 'Unknown' && userId) {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data().nama || 'Unknown';
        }
      }

      await db.collection('live_violations').add({
        quizId,
        studentId: userId,
        studentName: userName,
        reason: reason || 'Pelanggaran terdeteksi',
        timestamp: new Date().toISOString()
      });

      const violationsSnapshot = await db.collection('live_violations')
        .where('quizId', '==', quizId)
        .where('studentId', '==', userId)
        .get();

      const violationCount = violationsSnapshot.size;
      let autoSubmitTriggered = false;

      // NOTE: Auto-submit on 3 violations is disabled per user request. 
      // We only log the violations so they are visible to the Guru dashboard.

      res.status(200).json({ 
        message: 'Live violation logged',
        violationCount,
        autoSubmitTriggered
      });
    } catch (error) {
      res.status(500).json({ message: 'Error logging live violation', error: error.message });
    }
  },

  getLiveViolations: async (req, res) => {
    try {
      const quizId = req.params.id;
      // Fetching all for the quiz to sort in memory without missing index errors
      // In production with huge classes, a composite index should be added in Firebase
      const snapshot = await db.collection('live_violations')
        .where('quizId', '==', quizId)
        .get();

      const violations = [];
      snapshot.forEach(doc => violations.push({ id: doc.id, ...doc.data() }));

      // Sort in memory (descending timestamp)
      violations.sort((a, b) => {
        const dateA = a.timestamp ? new Date(a.timestamp) : new Date(0);
        const dateB = b.timestamp ? new Date(b.timestamp) : new Date(0);
        return dateB - dateA;
      });

      // After sorting, limit to top 50 latest
      const topViolations = violations.slice(0, 50);

      res.status(200).json({ data: topViolations });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching live violations', error: error.message });
    }
  },

  exportCsv: async (req, res) => {
    try {
      const quizDoc = await db.collection('quizzes').doc(req.params.id).get();
      if (!quizDoc.exists) {
        return res.status(404).json({ message: 'Kuis tidak ditemukan' });
      }

      let queryRef = db.collection('quiz_submissions')
        .where('quizId', '==', req.params.id);

      if (req.query.kelasId) {
        queryRef = queryRef.where('kelasId', '==', req.query.kelasId);
      }

      const snapshot = await queryRef.get();
      const rows = [['No', 'Nama Siswa', 'Skor', 'Total Poin', 'Persentase', 'Pelanggaran', 'Auto Submit', 'Waktu Submit']];

      let idx = 1;
      snapshot.forEach(doc => {
        const d = doc.data();
        const pct = d.totalPoints > 0 ? Math.round(d.score / d.totalPoints * 100) : 0;
        rows.push([
          idx++,
          d.studentName || '-',
          d.score || 0,
          d.totalPoints || 0,
          pct + '%',
          d.violations || 0,
          d.autoSubmitted ? 'Ya' : 'Tidak',
          d.submittedAt || '-',
        ]);
      });

      const csv = rows.map(r => r.join(',')).join('\n');

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="${quizDoc.data().title || 'export'}.csv"`);
      res.status(200).send(csv);
    } catch (error) {
      res.status(500).json({ message: 'Error export CSV', error: error.message });
    }
  },

  activateScheduled: async (req, res) => {
    try {
      const now = new Date().toISOString();
      const snapshot = await db.collection('quizzes')
        .where('isScheduled', '==', true)
        .where('isActive', '==', false)
        .get();

      let activated = 0;
      const batch = db.batch();

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.scheduledAt && data.scheduledAt <= now) {
          batch.update(doc.ref, { isActive: true, isScheduled: false, updatedAt: now });
          activated++;
        }
      });

      await batch.commit();
      res.status(200).json({ message: `${activated} kuis diaktifkan`, activated });
    } catch (error) {
      res.status(500).json({ message: 'Error activating scheduled quizzes', error: error.message });
    }
  },

  gradeEssay: async (req, res) => {
    try {
      const { submissionId } = req.params;
      const { essayScores } = req.body; // e.g., { "question_1": 15, "question_2": 10 }

      if (!essayScores || typeof essayScores !== 'object') {
        return res.status(400).json({ message: 'Format essayScores tidak valid' });
      }

      const submissionRef = db.collection('quiz_submissions').doc(submissionId);
      const doc = await submissionRef.get();
      if (!doc.exists) return res.status(404).json({ message: 'Submission tidak ditemukan' });

      const data = doc.data();
      let currentScore = data.score || 0;
      
      // If it was already manually graded, subtract old essay scores before adding new ones
      const oldEssayScores = data.essayScores || {};
      let scoreAdjustment = 0;

      for (let qId in essayScores) {
        const newPts = Number(essayScores[qId]) || 0;
        const oldPts = Number(oldEssayScores[qId]) || 0;
        scoreAdjustment += (newPts - oldPts);
        oldEssayScores[qId] = newPts;
      }

      await submissionRef.update({
        score: currentScore + scoreAdjustment,
        essayScores: oldEssayScores,
        hasEssayGraded: true,
        updatedAt: new Date().toISOString()
      });

      res.status(200).json({ message: 'Nilai essay berhasil disimpan', score: currentScore + scoreAdjustment });
    } catch (error) {
      res.status(500).json({ message: 'Error grading essay', error: error.message });
    }
  },

  aiGradeEssay: async (req, res) => {
    try {
      const { submissionId } = req.params;
      const { GEMINI_API_KEY } = process.env;

      if (!GEMINI_API_KEY) {
        return res.status(500).json({ message: 'GEMINI_API_KEY belum dikonfigurasi di server.' });
      }

      const submissionRef = db.collection('quiz_submissions').doc(submissionId);
      const subDoc = await submissionRef.get();
      if (!subDoc.exists) return res.status(404).json({ message: 'Submission tidak ditemukan' });

      const submission = subDoc.data();
      const quizId = submission.quizId;

      const quizDoc = await db.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) return res.status(404).json({ message: 'Kuis tidak ditemukan' });

      const quiz = quizDoc.data();
      const questions = quiz.questions || [];
      const essayAnswers = submission.essayAnswers || {};

      const { GoogleGenAI } = require('@google/genai');
      const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

      const essayScores = {};
      let totalPoints = 0;

      for (const q of questions) {
        if (q.questionType === 'essay' && essayAnswers[q.id]) {
          const studentAnswer = essayAnswers[q.id];
          const maxPoints = q.points || 10;
          const prompt = `Anda adalah seorang guru. Tolong nilai jawaban siswa untuk soal berikut.
Soal: "${q.question || q.text || ''}"
Kunci Jawaban/Panduan: "${q.correctAnswer || 'Nilai secara logis berdasarkan pemahaman'}"
Jawaban Siswa: "${studentAnswer}"

Berikan respons dalam format JSON yang valid dengan struktur berikut:
{
  "score": <angka dari 0 sampai ${maxPoints}>,
  "feedback": "<komentar singkat 1-2 kalimat mengapa nilai tersebut diberikan>"
}
Pastikan kembalian hanya JSON murni tanpa markdown \`\`\`.`;
          
          try {
            const response = await ai.models.generateContent({
              model: 'gemini-2.5-flash',
              contents: prompt,
            });
            let resultText = response.text.replace(/```json/gi, '').replace(/```/g, '').trim();
            let parsed = JSON.parse(resultText);
            
            let scoreNum = parseInt(parsed.score, 10);
            if (isNaN(scoreNum)) scoreNum = 0;
            if (scoreNum > maxPoints) scoreNum = maxPoints;
            
            essayScores[q.id] = {
              score: scoreNum,
              feedback: parsed.feedback || ''
            };
            totalPoints += scoreNum;
          } catch (aiErr) {
             console.error("AI Evaluation error:", aiErr.message);
             essayScores[q.id] = { score: 0, feedback: 'Gagal mengevaluasi dengan AI.' };
          }
        }
      }

      res.status(200).json({ 
        message: 'Grading AI selesai', 
        suggestedScores: essayScores,
        totalSuggested: totalPoints 
      });

    } catch (error) {
      res.status(500).json({ message: 'Error AI grading', error: error.message });
    }
  },
};

module.exports = quizController;
