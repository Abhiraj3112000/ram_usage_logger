import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MemoryLogger {
  static const _channel = MethodChannel("com.example/memory_usage");
  final Map<String, List<_MemoryEvent>> _logs = {};
  final Map<String, List<double>> _samples = {}; // Ongoing samples
  final Map<String, Timer> _timers = {}; // Active timers per route
  final Map<String, double> _routeBaselines = {}; // Baseline memory usage per route

  Future<double> _getMemoryUsage() async {
    final usage = await _channel.invokeMethod("getMemoryUsage");
    return (usage as num).toDouble();
  }

  /// Start sampling every 15ms when entering a route
  Future<void> logRouteEnter(String route) async {
    final usage = await _getMemoryUsage();
    _routeBaselines[route] = usage; // Set baseline at route entry
    _logs.putIfAbsent(route, () => []);
    _samples[route] = [usage]; // Initialize samples

    _logs[route]!.add(_MemoryEvent("Entered", usage, 0, "Baseline"));

    // Start periodic sampling every 15ms
    _timers[route] = Timer.periodic(const Duration(milliseconds: 15), (_) async {
      final sample = await _getMemoryUsage();
      _samples[route]!.add(sample);
    });
  }

  /// Stop sampling and log average when exiting
  Future<void> logRouteExit(String route) async {
    _timers[route]?.cancel();
    _timers.remove(route);

    final samples = _samples[route] ?? [];
    if (samples.isEmpty) return;

    final baseline = _routeBaselines[route] ?? samples.first;
    final average = samples.reduce((a, b) => a + b) / samples.length;
    final delta = average - baseline;
    final deltaPercent = (delta / baseline) * 100;

    final note = (delta > 30 || deltaPercent > 15)
        ? "⚠️ Possible leak"
        : "Normal fluctuation";

    _logs[route]!.add(_MemoryEvent("Exited", average, delta, note));

    _samples.remove(route);
  }

  /// Generate CSV output
  String generateCSV() {
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

  /// Save CSV report
  Future<String> saveReport() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/memory_report.csv");
    await file.writeAsString(generateCSV());
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