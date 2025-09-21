import 'package:flutter/material.dart';
import 'memory_logger.dart';

final memoryLogger = MemoryLogger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [MyRouteObserver()],
      routes: {
        '/': (_) => const HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/stress': (_) => const StressTestPage(),
      },
    );
  }
}

class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      memoryLogger.logRouteEnter(route.settings.name!);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      memoryLogger.logRouteExit(route.settings.name!);
      memoryLogger.saveReport(); // save automatically after pop
    }
    super.didPop(route, previousRoute);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: const Text("Go to Profile"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/stress'),
              child: const Text("Go to Stress Test"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => memoryLogger.shareReport(),
              child: const Text("Share Memory Report"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Back to Home"),
        ),
      ),
    );
  }
}

class StressTestPage extends StatelessWidget {
  const StressTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Extremely heavy memory load
    final bigList = List.generate(500000, (i) => "Item $i"); // 5x bigger
    final hugeStrings = List.generate(
      5,
      (i) {
        String s = "";
        for (int j = 0; j < 50000; j++) {
          s += "Flutter Rocks $i-$j ";
        }
        return s;
      },
    );

    // Keep a static reference to simulate memory retention
    StressTestPageHolder.hugeMemory.addAll(hugeStrings);

    return Scaffold(
      appBar: AppBar(title: const Text("Extreme Stress Test Page")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Text("Big List length: ${bigList.length}"),
                const SizedBox(height: 20),
                ...bigList.take(100).map((e) => Text(e)),
                const SizedBox(height: 20),
                ...hugeStrings
                    .map((s) => Text("Huge string length: ${s.length}")),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: 200, // load 200 images
              itemBuilder: (_, i) => Image.network(
                "https://picsum.photos/400/400?random=$i",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Static holder to simulate memory leak
class StressTestPageHolder {
  static List<String> hugeMemory = [];
}
