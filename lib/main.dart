import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/blocs/application_bloc.dart';
import 'package:todo/src/screens/home_page.dart';

void main() {
  return runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ApplicationBloc(),
        child: MaterialApp(theme: ThemeData(), home: const MyHomePage()
            // home: HomeScreen(),
            ));
    // return MaterialApp(
    // theme: ThemeData(),
    // home: const MyHomePage(), // メインページを作成
    // );
  }
}
