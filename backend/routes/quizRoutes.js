const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const quizController = require('../controllers/quizController');

router.get('/', verifyToken, quizController.getAll);
router.get('/join/:shareCode', verifyToken, quizController.joinByCode);
router.get('/:id', verifyToken, quizController.getById);
router.post('/', verifyToken, quizController.create);
router.put('/:id', verifyToken, quizController.update);
router.delete('/:id', verifyToken, quizController.remove);

router.post('/:id/share', verifyToken, quizController.shareToKelas);
router.post('/:id/submit', verifyToken, quizController.submitAnswers);
router.get('/:id/submissions', verifyToken, quizController.getSubmissions);
router.get('/:id/check', verifyToken, quizController.checkSubmission);
router.get('/:id/export', verifyToken, quizController.exportCsv);

router.post('/activate-scheduled', verifyToken, quizController.activateScheduled);

module.exports = router;
