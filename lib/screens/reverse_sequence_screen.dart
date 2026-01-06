import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum TokenCategory { digits, letters, specials }

class ReverseSequenceScreen extends StatefulWidget {
  const ReverseSequenceScreen({super.key});

  @override
  State<ReverseSequenceScreen> createState() => _ReverseSequenceScreenState();
}

class _ReverseSequenceScreenState extends State<ReverseSequenceScreen> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();

  Timer? _timer;

  final List<({int showMs, int pauseMs})> _speedPresets = const [
    (showMs: 2000, pauseMs: 700),
    (showMs: 1500, pauseMs: 600),
    (showMs: 1200, pauseMs: 500),
    (showMs: 900, pauseMs: 400),
    (showMs: 700, pauseMs: 300),
  ];
  int _speedPresetIndex = 2;

  int _length = 3;

  Set<TokenCategory> _enabledCategories = {
    TokenCategory.digits,
  };

  List<String> _tokens = [];
  int _tokenIndex = 0;
  bool _isRunning = false;
  bool _isPause = false;
  bool _awaitingAnswer = false;

  int _score = 0;
  int _correctInRow = 0;
  int _errorsInRow = 0;

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
      _tokens = _generateTokens(_length);
      _tokenIndex = 0;
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

    if (_tokenIndex >= _tokens.length) {
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
        _tokenIndex++;
      });
      _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].showMs));
      return;
    }

    setState(() {
      _isPause = true;
    });
    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].pauseMs));
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

  String _categoriesLabel() {
    final parts = <String>[];
    if (_enabledCategories.contains(TokenCategory.digits)) parts.add('цифры');
    if (_enabledCategories.contains(TokenCategory.letters)) parts.add('буквы');
    if (_enabledCategories.contains(TokenCategory.specials)) parts.add('спец');
    if (parts.isEmpty) return 'нет';
    return parts.join(', ');
  }

  Future<void> _showCategoriesDialog() async {
    final current = Set<TokenCategory>.from(_enabledCategories);
    Set<TokenCategory> temp = Set<TokenCategory>.from(_enabledCategories);

    final result = await showDialog<Set<TokenCategory>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Набор символов'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Цифры (0-9)'),
                    value: temp.contains(TokenCategory.digits),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(TokenCategory.digits);
                        } else {
                          temp.remove(TokenCategory.digits);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Буквы (A-Z)'),
                    value: temp.contains(TokenCategory.letters),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(TokenCategory.letters);
                        } else {
                          temp.remove(TokenCategory.letters);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Спецсимволы'),
                    value: temp.contains(TokenCategory.specials),
                    onChanged: (v) {
                      setLocalState(() {
                        if (v == true) {
                          temp.add(TokenCategory.specials);
                        } else {
                          temp.remove(TokenCategory.specials);
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
      _enabledCategories = result;
    });
  }

  List<String> _generateTokens(int length) {
    int clamped = length.clamp(1, 50);

    final pool = <String>[];

    if (_enabledCategories.contains(TokenCategory.digits)) {
      for (int i = 0; i <= 9; i++) {
        pool.add(i.toString());
      }
    }

    if (_enabledCategories.contains(TokenCategory.letters)) {
      for (int code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
        pool.add(String.fromCharCode(code));
      }
    }

    if (_enabledCategories.contains(TokenCategory.specials)) {
      pool.addAll(['!', '@', '#', r'$', '%', '&', '?', '*', '+', '-', '=', '/', '(', ')']);
    }

    if (pool.isEmpty) {
      pool.addAll(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
    }

    return List.generate(clamped, (_) => pool[_random.nextInt(pool.length)]);
  }

  List<String> _parseUserTokens(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];

    final bySpaces = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (bySpaces.length > 1) return bySpaces;

    return trimmed.split('').where((t) => t.isNotEmpty).toList();
  }

  void _submitAnswer() {
    if (!_awaitingAnswer) return;

    final userTokens = _parseUserTokens(_answerController.text);
    if (userTokens.isEmpty) return;

    final expected = _tokens.reversed.toList(growable: false);
    final isCorrect = userTokens.length == expected.length &&
        List.generate(expected.length, (i) => expected[i] == userTokens[i]).every((x) => x);

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
        _length = (_length + 1).clamp(1, 50);
        _correctInRow = 0;
      }

      if (_errorsInRow >= 3) {
        _length = (_length - 1).clamp(1, 50);
        _errorsInRow = 0;
      }

      final shown = _tokens.join(' ');
      final user = userTokens.join(' ');
      final exp = expected.join(' ');
      _history.add('$shown -> $user ${isCorrect ? "✓" : "✗ ($exp)"}');

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

  @override
  Widget build(BuildContext context) {
    String? currentText;
    if (_isRunning) {
      if (_isPause) {
        currentText = '';
      } else if (_tokenIndex < _tokens.length) {
        currentText = _tokens[_tokenIndex];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обратный счет (наоборот)'),
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
                Text('Набор: ${_categoriesLabel()}'),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showCategoriesDialog,
                  child: const Text('Выбрать'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _length > 1
                      ? () {
                          _applySettingsChange(() {
                            _length--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('Длина: $_length'),
                IconButton(
                  onPressed: _length < 50
                      ? () {
                          _applySettingsChange(() {
                            _length++;
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
                      currentText ?? (_awaitingAnswer ? 'Введите в обратном порядке' : 'Нажмите Старт'),
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
                      width: 260,
                      child: TextField(
                        controller: _answerController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
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
