import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  return runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(), // アプリのテーマカラーなど詳細を入力
      home: const MyHomePage(), // メインページを作成
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map> cards = [];

  final _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<List<Map>> _getCards() async {
    var prefs = await SharedPreferences.getInstance();
    var todo = prefs.getStringList("todo") ?? [];
    for (var jsonStr in todo) {
      cards.add(jsonDecode(jsonStr));
    }
    return cards;
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タイトル'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "文字列を入力してください。"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context, _textFieldController.text);
                _textFieldController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _todoWidget(int index) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(
                onChanged: (value) {
                  setState(() {
                    cards[index]['state'] = value ?? false;
                  });
                },
                value: cards[index]['state']),
            Text(cards[index]['title']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Todo"),
        actions: [
          IconButton(
              onPressed: () {
                SharedPreferences.getInstance().then((prefs) async {
                  await prefs.setStringList("todo", []);
                  setState(() {
                    cards = [];
                  });
                });
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: Center(
        child: FutureBuilder<List>(
            future: _getCards(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return const Text('Waiting to start');
                case ConnectionState.waiting:
                  return const Text('Loading...');
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _todoWidget(index);
                        });
                  }
              }
            }),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null && resultLabel != "") {
            setState(() {
              var mapObj = {'title': resultLabel, 'state': false};
              cards.add(mapObj);
              SharedPreferences.getInstance().then((prefs) async {
                var todo = prefs.getStringList("todo") ?? [];
                todo.add(jsonEncode(mapObj));
                await prefs.setStringList("todo", todo);
              });
            });
          }
        },
      ),
    );
  }
}
