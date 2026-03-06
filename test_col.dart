import 'dart:io';

void main() {
  final lines = File(
    "lib/data/models/emi_tracker_model.g.dart",
  ).readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.contains("as bool")) {
      print("Line ${i + 1}: 'as bool' at ${line.indexOf('as bool') + 1}");
    }
    if (line.contains("== null")) {
      print("Line ${i + 1}: '== null' at ${line.indexOf('== null') + 1}");
    }
  }
}
