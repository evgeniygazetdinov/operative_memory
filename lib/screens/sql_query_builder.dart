import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class SqlQueryBuilderScreen extends StatefulWidget {
  const SqlQueryBuilderScreen({super.key});

  @override
  State<SqlQueryBuilderScreen> createState() => _SqlQueryBuilderScreenState();
}

class _SqlQueryBuilderScreenState extends State<SqlQueryBuilderScreen> {
  final Random _random = Random();
  List<String> availableTokens = [];
  List<String> userSolution = [];
  List<String> correctTokens = [];
  bool isCorrect = false;

  // Примеры запросов с их частями
  final List<Map<String, dynamic>> queryTemplates = [
    {
      'tokens': [
        'SELECT *',
        'FROM',
        'employees',
        'INNER JOIN',
        'departments',
        'ON',
        'employees.dept_id',
        '=',
        'departments.id'
      ]
    },
    {
      'tokens': [
        'SELECT',
        'name, city',
        'FROM',
        'customers',
        'LEFT JOIN',
        'orders',
        'ON',
        'customers.id',
        '=',
        'orders.customer_id'
      ]
    },
    // Добавьте больше шаблонов запросов здесь
  ];

  @override
  void initState() {
    super.initState();
    generateNewExercise();
  }

  void generateNewExercise() {
    final template = queryTemplates[_random.nextInt(queryTemplates.length)];
    setState(() {
      correctTokens = List<String>.from(template['tokens']);
      availableTokens = List<String>.from(template['tokens'])..shuffle(_random);
      userSolution = [];
      isCorrect = false;
    });
  }

  void checkSolution() {
    setState(() {
      isCorrect = listEquals(userSolution, correctTokens);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Построитель SQL запросов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: generateNewExercise,
            tooltip: 'Новое упражнение',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Составьте правильный SQL запрос из предложенных частей',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Область для построения запроса
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: userSolution.map((token) => DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return Chip(
                    label: Text(token),
                    onDeleted: () {
                      setState(() {
                        userSolution.remove(token);
                        availableTokens.add(token);
                      });
                    },
                  );
                },
                // onWillAcceptWithDetails: (details) => details.data != null,
                onAcceptWithDetails: (details) {
                  setState(() {
                    final index = userSolution.indexOf(token);
                    if (index != -1) {
                      userSolution[index] = details.data;
                      availableTokens.remove(details.data);
                      if (!availableTokens.contains(token)) {
                        availableTokens.add(token);
                      }
                    }
                  });
                },
              )).toList(),
            ),
          ),
          // Доступные части запроса
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: availableTokens.map((token) => Draggable<String>(
                  data: token,
                  feedback: Material(
                    child: Chip(label: Text(token)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: Chip(label: Text(token)),
                  ),
                  child: Chip(label: Text(token)),

                )).toList(),
              ),
            ),
          ),
          // Кнопки управления
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (availableTokens.isNotEmpty) {
                        final token = availableTokens.removeAt(0);
                        userSolution.add(token);
                      }
                    });
                  },
                  child: const Text('Добавить'),
                ),
                ElevatedButton(
                  onPressed: checkSolution,
                  child: const Text('Проверить'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      availableTokens.addAll(userSolution);
                      userSolution.clear();
                    });
                  },
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),
          if (isCorrect)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Правильно! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}