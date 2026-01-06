import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class NBackStimulus {
  final int pos;
  final String letter;

  const NBackStimulus({required this.pos, required this.letter});
}

class NBackScreen extends StatefulWidget {
  const NBackScreen({super.key});

  @override
  State<NBackScreen> createState() => _NBackScreenState();
}

class _NBackScreenState extends State<NBackScreen> {
  final Random _random = Random();
  Timer? _timer;

  final List<({int showMs, int pauseMs})> _speedPresets = const [
    (showMs: 1200, pauseMs: 500),
    (showMs: 900, pauseMs: 400),
    (showMs: 800, pauseMs: 300),
    (showMs: 600, pauseMs: 250),
  ];
  int _speedPresetIndex = 2;

  int _n = 2;

  bool _isRunning = false;
  bool _isPause = false;
  bool _awaitingStart = true;

  final List<NBackStimulus> _history = [];
  final List<String> _events = [];

  NBackStimulus? _current;

  bool _pressedPos = false;
  bool _pressedLetter = false;

  int _posHits = 0;
  int _posMisses = 0;
  int _posFalseAlarms = 0;

  int _letterHits = 0;
  int _letterMisses = 0;
  int _letterFalseAlarms = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();

    setState(() {
      _isRunning = true;
      _isPause = false;
      _awaitingStart = false;

      _history.clear();
      _events.clear();
      _current = null;

      _pressedPos = false;
      _pressedLetter = false;

      _posHits = 0;
      _posMisses = 0;
      _posFalseAlarms = 0;

      _letterHits = 0;
      _letterMisses = 0;
      _letterFalseAlarms = 0;
    });

    _advanceToNextStimulus();
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPause = false;
      _awaitingStart = true;
    });
  }

  void _applySettingsChange(void Function() change) {
    _timer?.cancel();
    setState(change);
    if (_isRunning) {
      _start();
    }
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (!_isRunning) return;

    if (_isPause) {
      setState(() {
        _isPause = false;
      });
      _advanceToNextStimulus();
      return;
    }

    setState(() {
      _isPause = true;
    });
    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].pauseMs));
  }

  void _advanceToNextStimulus() {
    _evaluatePreviousTrial();

    final next = _generateStimulus();

    setState(() {
      _current = next;
      _history.add(next);

      _pressedPos = false;
      _pressedLetter = false;
    });

    _scheduleTick(Duration(milliseconds: _speedPresets[_speedPresetIndex].showMs));
  }

  NBackStimulus _generateStimulus() {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final pos = _random.nextInt(9);
    final letter = letters[_random.nextInt(letters.length)];
    return NBackStimulus(pos: pos, letter: letter);
  }

  bool _posMatchAt(int index) {
    if (index < _n) return false;
    return _history[index].pos == _history[index - _n].pos;
  }

  bool _letterMatchAt(int index) {
    if (index < _n) return false;
    return _history[index].letter == _history[index - _n].letter;
  }

  void _evaluatePreviousTrial() {
    if (_history.isEmpty) return;

    final idx = _history.length - 1;

    final posMatch = _posMatchAt(idx);
    final letterMatch = _letterMatchAt(idx);

    if (posMatch && _pressedPos) {
      _posHits++;
    } else if (posMatch && !_pressedPos) {
      _posMisses++;
    } else if (!posMatch && _pressedPos) {
      _posFalseAlarms++;
    }

    if (letterMatch && _pressedLetter) {
      _letterHits++;
    } else if (letterMatch && !_pressedLetter) {
      _letterMisses++;
    } else if (!letterMatch && _pressedLetter) {
      _letterFalseAlarms++;
    }

    final stimulus = _history[idx];
    final ev = '${idx + 1}: [${stimulus.letter}] pos=${stimulus.pos} | P:${posMatch ? "M" : "-"}/${_pressedPos ? "Y" : "n"} L:${letterMatch ? "M" : "-"}/${_pressedLetter ? "Y" : "n"}';
    _events.add(ev);
    if (_events.length > 200) {
      _events.removeAt(0);
    }
  }

  String _speedLabel() {
    final preset = _speedPresets[_speedPresetIndex];
    return '${preset.showMs}ms / ${preset.pauseMs}ms';
  }

  Widget _buildGrid() {
    final activeIndex = (!_isRunning || _isPause || _current == null) ? null : _current!.pos;

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isActive = activeIndex == index;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: isActive ? Colors.blue.shade300 : Colors.transparent,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letterText = (!_isRunning || _isPause || _current == null) ? '' : _current!.letter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('N-Back'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _start,
                child: const Text('Старт'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isRunning ? _stop : null,
                child: const Text('Стоп'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                const Text('N:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('2-back'),
                  selected: _n == 2,
                  onSelected: (_) {
                    _applySettingsChange(() {
                      _n = 2;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('3-back'),
                  selected: _n == 3,
                  onSelected: (_) {
                    _applySettingsChange(() {
                      _n = 3;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGrid(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              letterText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: !_isRunning
                                    ? null
                                    : () {
                                        setState(() {
                                          _pressedPos = true;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pressedPos ? Colors.blue.shade200 : null,
                                ),
                                child: const Text('Position'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: !_isRunning
                                    ? null
                                    : () {
                                        setState(() {
                                          _pressedLetter = true;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pressedLetter ? Colors.blue.shade200 : null,
                                ),
                                child: const Text('Letter'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Position: hit $_posHits, miss $_posMisses, false $_posFalseAlarms\n'
                            'Letter: hit $_letterHits, miss $_letterMisses, false $_letterFalseAlarms',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: _events.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                return Text(
                                  _events[_events.length - 1 - index],
                                  style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_awaitingStart)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Нажми Старт и отмечай совпадения с N шагов назад.'),
              ),
          ],
        ),
      ),
    );
  }
}
