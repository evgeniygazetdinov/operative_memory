import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../screens/game_modes.dart';
import '../screens/number_generator.dart';

class MathTrainerScreen extends StatefulWidget {
  final MathMode mode;
  
  const MathTrainerScreen({super.key, required this.mode});

  @override
  State<MathTrainerScreen> createState() => _MathTrainerScreenState();
}

class _MathTrainerScreenState extends State<MathTrainerScreen> {
  final TextEditingController _answerController = TextEditingController();
  late ConfettiController _confettiController;
  late NumberGenerator _numberGenerator;
  
  int currentSum = 0;
  int nextNumber = 0;
  int correctAnswers = 0;
  int currentLevel = 1;
  int errorCount = 0;
  bool isFirstNumber = true;
  List<String> exerciseHistory = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _numberGenerator = NumberGenerator(mode: widget.mode);
    _startNewExercise();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _showCelebration() {
    _confettiController.play();
  }

  void _startNewExercise() {
    if (widget.mode == MathMode.ascending) {
      if (isFirstNumber) {
        currentSum = _numberGenerator.generateNumber(currentLevel);
        isFirstNumber = false;
      }
      nextNumber = _numberGenerator.generateNumber(currentLevel);
    } else {
      // В режиме случайных чисел генерируем оба числа заново
      currentSum = _numberGenerator.generateNumber(currentLevel);
      nextNumber = _numberGenerator.generateNumber(currentLevel);
    }
    setState(() {});
  }

  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    int userAnswer = int.tryParse(_answerController.text) ?? 0;
    if (userAnswer == currentSum + nextNumber) {
      exerciseHistory.add('$currentSum + $nextNumber = $userAnswer ✓');
      
      setState(() {
        correctAnswers++;
        errorCount = 0;
        
        if (correctAnswers % 5 == 0) {
          currentLevel++;
          // В режиме возрастания сбрасываем генератор при повышении уровня
          if (widget.mode == MathMode.ascending) {
            _numberGenerator.reset();
            currentSum = 0;
          }
          if (correctAnswers % 10 == 0) {
            _showCelebration();
          }
        }
        
        if (widget.mode == MathMode.ascending) {
          currentSum = userAnswer; // Сохраняем результат только в режиме возрастания
        }
        _answerController.clear();
        _startNewExercise();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Правильно!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      exerciseHistory.add('$currentSum + $nextNumber = $userAnswer ');
      setState(() {
        errorCount++;
        if (errorCount >= 3) {
          if (currentLevel > 1) {
            currentLevel--;
          }
          errorCount = 0;
        }
        _answerController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неправильно!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                ' : $currentLevel',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        currentSum.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace',
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            nextNumber.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 2,
                        width: 120,
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _answerController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Monospace',
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _checkAnswer(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(''),
                ),
                const SizedBox(height: 20),
                Text(': $correctAnswers'),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: exerciseHistory.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      return Text(
                        exerciseHistory[exerciseHistory.length - 1 - index],
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}