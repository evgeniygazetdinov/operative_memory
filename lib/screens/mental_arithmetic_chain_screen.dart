import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum ChainOperation { add, subtract, multiply, divide }

class ChainStep {
  final ChainOperation op;
  final int value;

  const ChainStep({required this.op, required this.value});
}

class MentalArithmeticChainScreen extends StatefulWidget {
  const MentalArithmeticChainScreen({super.key});

  @override
  State<MentalArithmeticChainScreen> createState() => _MentalArithmeticChainScreenState();
}

class _MentalArithmeticChainScreenState extends State<MentalArithmeticChainScreen> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();

  Timer? _timer;

  final List<({int showMs, int pauseMs})> _speedPresets = const [
    (showMs: 1500, pauseMs: 600),
    (showMs: 1200, pauseMs: 500),
    (showMs: 900, pauseMs: 400),
    (showMs: 700, pauseMs: 300),
    (showMs: 500, pauseMs: 250),
    (showMs: 350, pauseMs: 200),
  ];
  int _speedPresetIndex = 3;

  int _stepsCount = 3;

  Set<ChainOperation> _enabledOps = {
    ChainOperation.add,
    ChainOperation.subtract,
  };

  int _level = 1;
  int _score = 0;
  int _correctInRow = 0;
  int _errorsInRow = 0;

  List<ChainStep> _steps = [];
  int _stepIndex = 0;
  bool _isRunning = false;
  bool _isPause = false;
  bool _awaitingAnswer = false;

  int _correctAnswer = 0;
  final List<String> _history = [];

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();

    setState(() {
      _steps = _generateSteps(level: _level, stepsCount: _stepsCount);
      _correctAnswer = _applySteps(0, _steps);
      _stepIndex = 0;
      _isRunning = true;
      _isPause = false;
      _awaitingAnswer = false;
      _answerController.clear();
    });

    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].showMs));
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _awaitingAnswer = false;
      _isPause = false;
    });
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;

    if (_stepIndex >= _steps.length) {
      setState(() {
        _isRunning = false;
        _awaitingAnswer = true;
        _isPause = false;
      });
      return;
    }

    if (_isPause) {
      setState(() {
        _isPause = false;
        _stepIndex++;
      });
      _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].showMs));
      return;
    }

    setState(() {
      _isPause = true;
    });
    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].pauseMs));
  }

  List<ChainStep> _generateSteps({required int level, required int stepsCount}) {
    int clampedStepsCount = stepsCount.clamp(1, 50);

    int maxAbs = 9 + (level - 1) * 5;
    maxAbs = maxAbs.clamp(9, 99);

    List<ChainStep> result = [];
    int running = 0;

    for (int i = 0; i < clampedStepsCount; i++) {
      final step = _generateStep(level: level, maxAbs: maxAbs, running: running);
      running = _applyStep(running, step);
      result.add(step);
    }

    return result;
  }

  ChainStep _generateStep({required int level, required int maxAbs, required int running}) {
    final ops = _enabledOps.isEmpty
        ? [ChainOperation.add]
        : _enabledOps.toList(growable: false);

    final chosen = ops[_random.nextInt(ops.length)];

    switch (chosen) {
      case ChainOperation.add:
      case ChainOperation.subtract:
        int value = 1 + _random.nextInt(maxAbs);
        final step = ChainStep(
          op: chosen,
          value: value,
        );

        int next = _applyStep(running, step);
        if (next < -999 || next > 999) {
          final flipped = ChainStep(
            op: chosen == ChainOperation.add ? ChainOperation.subtract : ChainOperation.add,
            value: value,
          );
          return flipped;
        }
        return step;

      case ChainOperation.multiply:
        int maxMul = 3 + (level / 2).floor();
        maxMul = maxMul.clamp(3, 9);
        int value = 2 + _random.nextInt(maxMul - 1);
        final step = ChainStep(op: ChainOperation.multiply, value: value);

        int next = _applyStep(running, step);
        if (next < -999 || next > 999) {
          return const ChainStep(op: ChainOperation.multiply, value: 2);
        }
        return step;

      case ChainOperation.divide:
        int maxDiv = 3 + (level / 2).floor();
        maxDiv = maxDiv.clamp(3, 9);

        for (int attempt = 0; attempt < 10; attempt++) {
          int divisor = 2 + _random.nextInt(maxDiv - 1);
          if (divisor == 0) continue;
          if (running == 0) continue;
          if (running % divisor != 0) continue;
          return ChainStep(op: ChainOperation.divide, value: divisor);
        }

        int value = 1 + _random.nextInt(maxAbs);
        return ChainStep(op: ChainOperation.add, value: value);
    }
  }

  int _applySteps(int initial, List<ChainStep> steps) {
    int running = initial;
    for (final s in steps) {
      running = _applyStep(running, s);
    }
    return running;
  }

  int _applyStep(int running, ChainStep step) {
    switch (step.op) {
      case ChainOperation.add:
        return running + step.value;
      case ChainOperation.subtract:
        return running - step.value;
      case ChainOperation.multiply:
        return running * step.value;
      case ChainOperation.divide:
        return running ~/ step.value;
    }
  }

  void _applySettingsChange(void Function() change) {
    _timer?.cancel();
    setState(change);
    if (_isRunning || _awaitingAnswer) {
      _start();
    }
  }

  String _speedLabel() {
    final preset = _speedPresets[_speedPresetIndex];
    return '${preset.showMs}ms / ${preset.pauseMs}ms';
  }

  String _operationsLabel() {
    final parts = <String>[];
    if (_enabledOps.contains(ChainOperation.add)) parts.add('+');
    if (_enabledOps.contains(ChainOperation.subtract)) parts.add('-');
    if (_enabledOps.contains(ChainOperation.multiply)) parts.add('*');
    if (_enabledOps.contains(ChainOperation.divide)) parts.add('/');
    if (parts.isEmpty) return 'нет';
    return parts.join(' ');
  }

  Future<void> _showOperationsDialog() async {
    final current = Set<ChainOperation>.from(_enabledOps);
    Set<ChainOperation> temp = Set<ChainOperation>.from(_enabledOps);

    final result = await showDialog<Set<ChainOperation>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Операции'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('+'),
                    value: temp.contains(ChainOperation.add),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(ChainOperation.add);
                        } else {
                          temp.remove(ChainOperation.add);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('-'),
                    value: temp.contains(ChainOperation.subtract),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(ChainOperation.subtract);
                        } else {
                          temp.remove(ChainOperation.subtract);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('*'),
                    value: temp.contains(ChainOperation.multiply),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(ChainOperation.multiply);
                        } else {
                          temp.remove(ChainOperation.multiply);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('/'),
                    value: temp.contains(ChainOperation.divide),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(ChainOperation.divide);
                        } else {
                          temp.remove(ChainOperation.divide);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('ОК'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    if (result.length == current.length && result.containsAll(current)) return;

    _applySettingsChange(() {
      _enabledOps = result;
    });
  }

  void _submitAnswer() {
    if (!_awaitingAnswer) return;

    int? userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null) return;

    bool isCorrect = userAnswer == _correctAnswer;

    setState(() {
      if (isCorrect) {
        _score++;
        _correctInRow++;
        _errorsInRow = 0;
      } else {
        _errorsInRow++;
        _correctInRow = 0;
      }

      if (_correctInRow >= 5) {
        _level++;
        _correctInRow = 0;
      }

      if (_errorsInRow >= 3) {
        if (_level > 1) {
          _level--;
        }
        _errorsInRow = 0;
      }

      _history.add('${_steps.map(_formatStep).join(" ")} = $userAnswer ${isCorrect ? "✓" : "✗ ($_correctAnswer)"}');
      _answerController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Правильно!' : 'Неправильно!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );

    _start();
  }

  String _formatStep(ChainStep step) {
    switch (step.op) {
      case ChainOperation.add:
        return '+${step.value}';
      case ChainOperation.subtract:
        return '-${step.value}';
      case ChainOperation.multiply:
        return '*${step.value}';
      case ChainOperation.divide:
        return '/${step.value}';
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentText;
    if (_isRunning) {
      if (_isPause) {
        currentText = '';
      } else if (_stepIndex < _steps.length) {
        currentText = _formatStep(_steps[_stepIndex]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ментальная арифметика (цепочки)'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Уровень: $_level',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Счет: $_score',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _speedPresetIndex > 0
                      ? () {
                          _applySettingsChange(() {
                            _speedPresetIndex--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('Скорость: ${_speedLabel()}'),
                IconButton(
                  onPressed: _speedPresetIndex < _speedPresets.length - 1
                      ? () {
                          _applySettingsChange(() {
                            _speedPresetIndex++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Операции: ${_operationsLabel()}'),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showOperationsDialog,
                  child: const Text('Выбрать'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _stepsCount > 1
                      ? () {
                          _applySettingsChange(() {
                            _stepsCount--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('Длина цепочки: $_stepsCount'),
                IconButton(
                  onPressed: _stepsCount < 50
                      ? () {
                          _applySettingsChange(() {
                            _stepsCount++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentText ?? (_awaitingAnswer ? 'Введите итог' : 'Нажмите Старт'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_awaitingAnswer)
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _answerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace',
                        ),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _submitAnswer(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isRunning ? null : _start,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Старт'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (!_awaitingAnswer || _isRunning) ? null : _submitAnswer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('ОК'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (_isRunning || _awaitingAnswer) ? _stop : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Стоп'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 180,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _history.length,
                reverse: true,
                itemBuilder: (context, index) {
                  return Text(
                    _history[_history.length - 1 - index],
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
