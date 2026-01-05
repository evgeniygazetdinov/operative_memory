#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Начинаем установку приложения для тренировки устного счета...${NC}\n"

# Проверка наличия Flutter
echo -e "Проверка Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "Flutter не установлен! Пожалуйста, установите Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Проверка зависимостей Flutter
echo -e "\n${YELLOW}Проверка зависимостей Flutter...${NC}"
flutter doctor

# Очистка проекта
echo -e "\n${YELLOW}Очистка проекта...${NC}"
flutter clean

# Получение зависимостей
echo -e "\n${YELLOW}Установка зависимостей...${NC}"
flutter pub get

# Проверка на ошибки
echo -e "\n${YELLOW}Проверка на ошибки...${NC}"
flutter analyze

# Сборка APK
echo -e "\n${YELLOW}Сборка APK...${NC}"
flutter build apk

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Установка успешно завершена!${NC}"
    echo -e "\nДля запуска приложения выполните:"
    echo -e "${YELLOW}flutter run${NC}"
    echo -e "\nAPK файл доступен по пути:"
    echo -e "${YELLOW}build/app/outputs/flutter-apk/app-release.apk${NC}"
else
    echo -e "\nПроизошла ошибка при сборке. Пожалуйста, проверьте логи выше."
fi