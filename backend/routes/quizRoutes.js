const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const quizController = require('../controllers/quizController');

// ─── Quiz CRUD Routes ───────────────────────────────────────────────────────

// GET /api/quiz — List quizzes (filter by kelasId or createdBy)
router.get('/', verifyToken, quizController.getAll);

// GET /api/quiz/:id — Get quiz detail
router.get('/:id', verifyToken, quizController.getById);

// POST /api/quiz — Create quiz (Guru only)
router.post('/', verifyToken, quizController.create);

// PUT /api/quiz/:id — Update quiz
router.put('/:id', verifyToken, quizController.update);

// DELETE /api/quiz/:id — Delete quiz
router.delete('/:id', verifyToken, quizController.remove);

// ─── Quiz Submission Routes ─────────────────────────────────────────────────

// POST /api/quiz/:id/submit — Submit answers
router.post('/:id/submit', verifyToken, quizController.submitAnswers);

// GET /api/quiz/:id/submissions — Get all submissions (for Guru)
router.get('/:id/submissions', verifyToken, quizController.getSubmissions);

// GET /api/quiz/:id/check — Check if student already submitted
router.get('/:id/check', verifyToken, quizController.checkSubmission);

module.exports = router;
