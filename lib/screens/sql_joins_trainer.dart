import 'package:flutter/material.dart';
import 'dart:math';

class SqlJoinsTrainerScreen extends StatefulWidget {
  const SqlJoinsTrainerScreen({super.key});

  @override
  State<SqlJoinsTrainerScreen> createState() => _SqlJoinsTrainerScreenState();
}

class _SqlJoinsTrainerScreenState extends State<SqlJoinsTrainerScreen> {
  final Random _random = Random();
  List<Map<String, dynamic>> tableA = [];
  List<Map<String, dynamic>> tableB = [];
  String currentJoinType = '';
  bool showAnswer = false;
  
  // Списки возможных данных для генерации
  final List<String> names = [
    'John', 'Jane', 'Bob', 'Alice', 'Charlie', 
    'David', 'Eva', 'Frank', 'Grace', 'Henry'
  ];
  
  final List<String> cities = [
    'New York', 'London', 'Paris', 'Tokyo', 'Berlin',
    'Moscow', 'Rome', 'Madrid', 'Toronto', 'Sydney'
  ];

  @override
  void initState() {
    super.initState();
    generateNewExercise();
  }

  void generateNewExercise() {
    setState(() {
      tableA = _generateRandomTable(true);
      tableB = _generateRandomTable(false);
      showAnswer = false;
      currentJoinType = _getRandomJoinType();
    });
  }

  List<Map<String, dynamic>> _generateRandomTable(bool isTableA) {
    int rowCount = _random.nextInt(3) + 3; // 3-5 строк
    List<Map<String, dynamic>> table = [];
    Set<int> usedIds = {}; // Для уникальных ID

    for (int i = 0; i < rowCount; i++) {
      int id;
      do {
        id = _random.nextInt(8) + 1; // ID от 1 до 8
      } while (usedIds.contains(id));
      usedIds.add(id);

      if (isTableA) {
        table.add({
          'id': id,
          'name': names[_random.nextInt(names.length)],
        });
      } else {
        table.add({
          'id': id,
          'city': cities[_random.nextInt(cities.length)],
        });
      }
    }
    return table;
  }

  String _getRandomJoinType() {
    final joinTypes = [
      'INNER JOIN',
      'LEFT OUTER JOIN',
      'RIGHT OUTER JOIN',
      'FULL OUTER JOIN'
    ];
    return joinTypes[_random.nextInt(joinTypes.length)];
  }

  List<Map<String, dynamic>> _calculateJoinResult() {
    List<Map<String, dynamic>> result = [];
    
    switch (currentJoinType) {
      case 'INNER JOIN':
        for (var a in tableA) {
          for (var b in tableB) {
            if (a['id'] == b['id']) {
              result.add({
                'id': a['id'],
                'name': a['name'],
                'city': b['city'],
              });
            }
          }
        }
        break;
      case 'LEFT OUTER JOIN':
        for (var a in tableA) {
          bool found = false;
          for (var b in tableB) {
            if (a['id'] == b['id']) {
              found = true;
              result.add({
                'id': a['id'],
                'name': a['name'],
                'city': b['city'],
              });
            }
          }
          if (!found) {
            result.add({
              'id': a['id'],
              'name': a['name'],
              'city': null,
            });
          }
        }
        break;
      // Добавьте остальные типы JOIN здесь
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL JOIN Тренажер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: generateNewExercise,
            tooltip: 'Новое упражнение',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Текущее задание: $currentJoinType',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _buildTableVisualization('Таблица A (Сотрудники)', tableA),
              const SizedBox(height: 20),
              _buildTableVisualization('Таблица B (Города)', tableB),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showAnswer = !showAnswer;
                  });
                },
                child: Text(showAnswer ? 'Скрыть результат' : 'Показать результат'),
              ),
              if (showAnswer) ...[
                const SizedBox(height: 20),
                _buildTableVisualization('Результат', _calculateJoinResult()),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generateNewExercise,
        tooltip: 'Следующее упражнение',
        child: const Icon(Icons.shuffle),

      ),
    );
  }

  Widget _buildTableVisualization(String title, List<Map<String, dynamic>> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: data.isEmpty
                    ? []
                    : data.first.keys.map((key) {
                        return DataColumn(label: Text(key));
                      }).toList(),
                rows: data.map((row) {
                  return DataRow(
                    cells: row.values.map((value) {
                      return DataCell(Text(value?.toString() ?? 'NULL'));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}