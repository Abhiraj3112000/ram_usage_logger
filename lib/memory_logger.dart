import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MemoryLogger {
  static const _channel = MethodChannel("com.example/memory_usage");
  final Map<String, List<_MemoryEvent>> _logs = {};

  Future<double> _getMemoryUsage() async {
    final usage = await _channel.invokeMethod("getMemoryUsage");
    return (usage as num).toDouble();
  }

  Future<void> logRouteEnter(String route) async {
    final usage = await _getMemoryUsage();
    _logs.putIfAbsent(route, () => []);
    _logs[route]!.add(_MemoryEvent("Entered", usage, 0, "Baseline"));
  }

  Future<void> logRouteExit(String route) async {
    final usage = await _getMemoryUsage();
    final baseline = _logs[route]!.first.memory;
    final delta = usage - baseline;
    final deltaPercent = (delta / baseline) * 100;

    final note = (delta > 20 || deltaPercent > 10)
        ? "⚠️ Possible leak"
        : "Normal fluctuation";

    _logs[route]!.add(_MemoryEvent("Exited", usage, delta, note));
  }

  /// Generate CSV content
  String generateCsv() {
    final buffer = StringBuffer();
    buffer.writeln("Route,Event,Memory (MB),Delta (MB),Notes");

    _logs.forEach((route, events) {
      for (var e in events) {
        buffer.writeln(
            "$route,${e.event},${e.memory.toStringAsFixed(2)},${e.delta.toStringAsFixed(2)},${e.notes}");
      }
    });

    return buffer.toString();
  }

  /// Save CSV in Documents folder
  Future<String> saveReport() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/memory_report.csv");
    await file.writeAsString(generateCsv());
    if (kDebugMode) {
      print("📄 CSV Report saved at: ${file.path}");
    }
    return file.path;
  }

  /// Share CSV report
  Future<void> shareReport() async {
    final path = await saveReport();
    await Share.shareXFiles([XFile(path)],
        text: "Memory Profiling Report (CSV)");
  }
}

class _MemoryEvent {
  final String event;
  final double memory;
  final double delta;
  final String notes;
  _MemoryEvent(this.event, this.memory, this.delta, this.notes);
}
