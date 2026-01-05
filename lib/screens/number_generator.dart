import 'dart:math';
import 'game_modes.dart';

class NumberGenerator {
  final MathMode mode;
  final Random _random = Random();
  int _currentNumber = 1;  // Добавляем счетчик для режима возрастания
  
  NumberGenerator({required this.mode});
  
  int generateNumber(int currentLevel) {
    if (mode == MathMode.ascending) {
      // В режиме возрастания просто возвращаем текущее число и увеличиваем его на 1
      int number = _currentNumber;
      _currentNumber++;
      return number;
    } else {
      // В режиме случайных чисел генерируем числа в зависимости от уровня
      int maxDigits = (currentLevel / 3).ceil();
      maxDigits = maxDigits.clamp(1, 4);
      
      int minNumber = pow(10, maxDigits - 1).toInt();
      int maxNumber = pow(10, maxDigits).toInt() - 1;
      
      return minNumber + _random.nextInt(maxNumber - minNumber + 1);
    }
  }
  
  // Метод для сброса счетчика при необходимости начать сначала
  void reset() {
    _currentNumber = 1;
  }
}