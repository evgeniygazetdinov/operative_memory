import 'package:flutter/material.dart';

Future<T?> showSettingsDialog<T>({
  required BuildContext context,
  required String title,
  required T initialValue,
  required Widget Function(BuildContext context, T value, void Function(T nextValue) setValue)
      contentBuilder,
}) {
  T value = initialValue;

  return showDialog<T>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          void setValue(T nextValue) {
            setLocalState(() {
              value = nextValue;
            });
          }

          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: contentBuilder(context, value, setValue),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(value),
                child: const Text('ОК'),
              ),
            ],
          );
        },
      );
    },
  );
}
