import 'package:flutter/material.dart';
import 'dart:math';

// Перечисление режимов логических операций
enum LogicMode { boolean, loop }

class LogicExpressionsScreen extends StatefulWidget {
  const LogicExpressionsScreen({super.key});

  @override
  State<LogicExpressionsScreen> createState() => _LogicExpressionsScreenState();
}

class _LogicExpressionsScreenState extends State<LogicExpressionsScreen> {
  LogicMode? selectedMode;

  @override
  Widget build(BuildContext context) {
    // Если режим не выбран, показываем экран выбора
    if (selectedMode == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Логические выражения'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  setState(() {
                    selectedMode = LogicMode.boolean;
                  });
                },
                child: const Text('Булевы операции'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  setState(() {
                    selectedMode = LogicMode.loop;
                  });
                },
                child: const Text('Циклические операции'),
              ),
            ],
          ),
        ),
      );
    }

    // Если выбран режим, показываем соответствующий контент
    return selectedMode == LogicMode.boolean
        ? const BooleanOperationsScreen()
        : const LoopOperationsScreen();
  }
}

// Экран для булевых операций
class BooleanOperationsScreen extends StatefulWidget {
  const BooleanOperationsScreen({super.key});
  @override
  State<BooleanOperationsScreen> createState() => _BooleanOperationsScreenState();
}

class _BooleanOperationsScreenState extends State<BooleanOperationsScreen> {
  final Random _random = Random();
  List<bool> variables = [];
  List<String> operations = [];
  String currentExpression = '';
  bool correctAnswer = false;
  int score = 0;
  int currentStep = 0;
  int totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _generateNewExpression();
  }

  void _generateNewExpression() {
    variables = List.generate(4, (index) => _random.nextBool());
    operations = List.generate(3, (index) => _getRandomOperation());
    currentStep = 0;
    _generateNextStep();
  }

  String _getRandomOperation() {
    final ops = ['И', 'ИЛИ', 'НЕ'];
    return ops[_random.nextInt(ops.length)];
  }

  void _generateNextStep() {
    if (currentStep >= totalSteps) {
      _generateNewExpression();
      return;
    }

    setState(() {
      String varA = 'a$currentStep';
      String varB = 'a$currentStep + 1';
      String operation = operations[currentStep];
      
      currentExpression = '''
Шаг ${currentStep + 1} из $totalSteps:
$varA = ${variables[currentStep]}
$varB = ${variables[currentStep + 1]}
Результат операции "$varA $operation $varB"?
''';

      correctAnswer = _calculateAnswer(
        variables[currentStep],
        variables[currentStep + 1],
        operation
      );
    });
  }

  bool _calculateAnswer(bool value1, bool value2, String operator) {
    switch (operator) {
      case 'И':
        return value1 && value2;
      case 'ИЛИ':
        return value1 || value2;
      case 'НЕ':
        return !value1;
      default:
        return false;
    }
  }

  void _handleAnswer(bool userAnswer) {
    bool isCorrect = userAnswer == correctAnswer;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Правильно!' : 'Неправильно!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );

    if (isCorrect) {
      setState(() {
        score++;
      });
    }

    currentStep++;
    if (currentStep < totalSteps) {
      _generateNextStep();
    } else {
      _generateNewExpression();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Булевы операции'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LogicExpressionsScreen(),
              ),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Счет: $score',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentExpression,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleAnswer(true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('ИСТИНА'),
                ),
                ElevatedButton(
                  onPressed: () => _handleAnswer(false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('ЛОЖЬ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Экран для циклических операций
class LoopOperationsScreen extends StatefulWidget {
  const LoopOperationsScreen({super.key});
  @override
  State<LoopOperationsScreen> createState() => _LoopOperationsScreenState();
}

class _LoopOperationsScreenState extends State<LoopOperationsScreen> {
  final Random _random = Random();
  List<int> numbers = [];
  int currentIndex = 1;  // Начинаем с 1, так как сравниваем с предыдущим
  String currentExpression = '';
  bool correctAnswer = false;
  int score = 0;
  int direction = 0;  // 0 - не определено, 1 - возрастание, -1 - убывание
  bool isMonotonic = true;

  @override
  void initState() {
    super.initState();
    _generateNewSequence();
  }

  void _generateNewSequence() {
    // Генерируем новую последовательность из 5 чисел
    numbers = List.generate(5, (index) => _random.nextInt(20));
    currentIndex = 1;
    direction = 0;
    isMonotonic = true;
    _generateNextStep();
  }

  void _generateNextStep() {
    if (currentIndex >= numbers.length) {
      _generateNewSequence();
      return;
    }

    setState(() {
      // Показываем текущий шаг и просим угадать следующее число
      String sequence = numbers.sublist(0, currentIndex).join(', ');
      
      currentExpression = '''
Последовательность: [$sequence, ?]

Текущий индекс: $currentIndex
Предыдущее число: ${numbers[currentIndex - 1]}

Верно ли что следующее число БОЛЬШЕ предыдущего?
(т.е. nums[$currentIndex] > nums[${currentIndex - 1}])
''';

      // Определяем правильный ответ
      correctAnswer = numbers[currentIndex] > numbers[currentIndex - 1];

      // Обновляем direction для проверки монотонности
      if (numbers[currentIndex] > numbers[currentIndex - 1]) {
        if (direction == 0) 
        {
          direction = 1;
        }
        else if (direction == -1)
        { 
          isMonotonic = false;
        }
      } else if (numbers[currentIndex] < numbers[currentIndex - 1]) {
        if (direction == 0) 
        {direction = -1;}
        else if (direction == 1){
           isMonotonic = false;
        }
      }
    });
  }

  void _handleAnswer(bool userAnswer) {
    bool isCorrect = userAnswer == correctAnswer;
    
    setState(() {
      // Показываем результат текущего шага
      String sequence = numbers.sublist(0, currentIndex + 1).join(', ');
      String message = '''
Последовательность: [$sequence]

${isCorrect ? 'Правильно!' : 'Неправильно!'}
nums[$currentIndex] = ${numbers[currentIndex]}

${currentIndex == numbers.length - 1 ? '''
Последовательность ${isMonotonic ? 'ЯВЛЯЕТСЯ' : 'НЕ ЯВЛЯЕТСЯ'} монотонной.
Направление: ${direction == 1 ? 'возрастающая' : direction == -1 ? 'убывающая' : 'не определено'}
''' : ''}
''';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      if (isCorrect) score++;
    });

    // Переходим к следующему шагу
    currentIndex++;
    Future.delayed(const Duration(seconds: 2), () {
      _generateNextStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Монотонные последовательности'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LogicExpressionsScreen(),
              ),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Счет: $score',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentExpression,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleAnswer(true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('БОЛЬШЕ'),
                ),
                ElevatedButton(
                  onPressed: () => _handleAnswer(false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('НЕ БОЛЬШЕ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}