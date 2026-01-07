import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../widgets/settings_dialog.dart';

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

  static const Duration _betweenChainsDelay = Duration(milliseconds: 1000);

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
  List<ChainStep> _lastSteps = [];
  int _stepIndex = 0;
  bool _isRunning = false;
  bool _isPause = false;
  bool _awaitingAnswer = false;
  bool _isTransition = false;

  int _correctAnswer = 0;
  int _lastCorrectAnswer = 0;
  final List<String> _history = [];

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _showSettingsDialog() async {
    final initial = (
      speedPresetIndex: _speedPresetIndex,
      stepsCount: _stepsCount,
      ops: Set<ChainOperation>.from(_enabledOps),
    );

    final next = await showSettingsDialog(
      context: context,
      title: 'Настройки',
      initialValue: initial,
      contentBuilder: (context, value, setValue) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value.speedPresetIndex > 0
                      ? () => setValue((
                            speedPresetIndex: value.speedPresetIndex - 1,
                            stepsCount: value.stepsCount,
                            ops: value.ops,
                          ))
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  'Скорость: ${_speedPresets[value.speedPresetIndex].showMs}ms / ${_speedPresets[value.speedPresetIndex].pauseMs}ms',
                ),
                IconButton(
                  onPressed: value.speedPresetIndex < _speedPresets.length - 1
                      ? () => setValue((
                            speedPresetIndex: value.speedPresetIndex + 1,
                            stepsCount: value.stepsCount,
                            ops: value.ops,
                          ))
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value.stepsCount > 1
                      ? () => setValue((
                            speedPresetIndex: value.speedPresetIndex,
                            stepsCount: value.stepsCount - 1,
                            ops: value.ops,
                          ))
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('Длина цепочки: ${value.stepsCount}'),
                IconButton(
                  onPressed: value.stepsCount < 50
                      ? () => setValue((
                            speedPresetIndex: value.speedPresetIndex,
                            stepsCount: value.stepsCount + 1,
                            ops: value.ops,
                          ))
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('+'),
              value: value.ops.contains(ChainOperation.add),
              onChanged: (v) {
                final nextOps = Set<ChainOperation>.from(value.ops);
                if (v == true) {
                  nextOps.add(ChainOperation.add);
                } else {
                  nextOps.remove(ChainOperation.add);
                }
                setValue((
                  speedPresetIndex: value.speedPresetIndex,
                  stepsCount: value.stepsCount,
                  ops: nextOps,
                ));
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('-'),
              value: value.ops.contains(ChainOperation.subtract),
              onChanged: (v) {
                final nextOps = Set<ChainOperation>.from(value.ops);
                if (v == true) {
                  nextOps.add(ChainOperation.subtract);
                } else {
                  nextOps.remove(ChainOperation.subtract);
                }
                setValue((
                  speedPresetIndex: value.speedPresetIndex,
                  stepsCount: value.stepsCount,
                  ops: nextOps,
                ));
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('*'),
              value: value.ops.contains(ChainOperation.multiply),
              onChanged: (v) {
                final nextOps = Set<ChainOperation>.from(value.ops);
                if (v == true) {
                  nextOps.add(ChainOperation.multiply);
                } else {
                  nextOps.remove(ChainOperation.multiply);
                }
                setValue((
                  speedPresetIndex: value.speedPresetIndex,
                  stepsCount: value.stepsCount,
                  ops: nextOps,
                ));
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('/'),
              value: value.ops.contains(ChainOperation.divide),
              onChanged: (v) {
                final nextOps = Set<ChainOperation>.from(value.ops);
                if (v == true) {
                  nextOps.add(ChainOperation.divide);
                } else {
                  nextOps.remove(ChainOperation.divide);
                }
                setValue((
                  speedPresetIndex: value.speedPresetIndex,
                  stepsCount: value.stepsCount,
                  ops: nextOps,
                ));
              },
            ),
          ],
        );
      },
    );

    if (next == null) return;

    final changed = next.speedPresetIndex != initial.speedPresetIndex ||
        next.stepsCount != initial.stepsCount ||
        !next.ops.containsAll(initial.ops) ||
        !initial.ops.containsAll(next.ops);
    if (!changed) return;

    _applySettingsChange(() {
      _speedPresetIndex = next.speedPresetIndex;
      _stepsCount = next.stepsCount;
      _enabledOps = next.ops;
    });
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

  void _replayLast() {
    if (_lastSteps.isEmpty) return;

    _timer?.cancel();
    setState(() {
      _steps = List<ChainStep>.from(_lastSteps);
      _correctAnswer = _lastCorrectAnswer;
      _stepIndex = 0;
      _isRunning = true;
      _isPause = false;
      _awaitingAnswer = false;
      _answerController.clear();
    });

    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].showMs));
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;

    if (_stepIndex >= _steps.length) {
      setState(() {
        if (_steps.isNotEmpty) {
          _lastSteps = List<ChainStep>.from(_steps);
          _lastCorrectAnswer = _correctAnswer;
        }
        _isRunning = false;
        _isPause = false;
        _awaitingAnswer = false;
        _isTransition = true;
      });

      _timer?.cancel();
      _timer = Timer(_betweenChainsDelay, () {
        if (!mounted) return;
        setState(() {
          _awaitingAnswer = true;
          _isTransition = false;
        });
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

    _timer?.cancel();
    setState(() {
      _awaitingAnswer = false;
      _isTransition = true;
    });

    _timer = Timer(_betweenChainsDelay, () {
      if (!mounted) return;
      _start();
    });
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
    } else if (_isTransition) {
      currentText = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ментальная арифметика (цепочки)'),
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _start,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Старт'),
              ),
              ElevatedButton(
                onPressed: _lastSteps.isNotEmpty && !_isRunning ? _replayLast : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Показать еще раз'),
              ),
              ElevatedButton(
                onPressed: (!_awaitingAnswer || _isRunning) ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('ОК'),
              ),
              ElevatedButton(
                onPressed: (_isRunning || _awaitingAnswer) ? _stop : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Стоп'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Счет: $_score',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
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
      ),
    );
  }
}
