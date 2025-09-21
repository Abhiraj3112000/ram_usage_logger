import 'package:flutter/material.dart';
import 'memory_logger.dart';

final memoryLogger = MemoryLogger();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [MyRouteObserver()],
      routes: {
        '/': (_) => HomePage(),
        '/profile': (_) => ProfilePage(),
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
      memoryLogger.saveReport(); // automatically save after each pop
    }
    super.didPop(route, previousRoute);
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: Text("Go to Profile"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => memoryLogger.shareReport(),
              child: Text("Share Memory Report"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Back to Home"),
        ),
      ),
    );
  }
}