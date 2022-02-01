import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

///////////////////////////////
// ① Main：Flutterアプリもmain()からコードが実行されます。
// `void main() => runApp(MyApp());` でも意味は同じです。
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
  List<Widget> cards = [];
  final _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>> _getCards() async {
    var prefs = await SharedPreferences.getInstance();
    List<Widget> cards = [];
    var todo = prefs.getStringList("todo") ?? [];
    for (var jsonStr in todo) {
      // JSON形式の文字列から辞書形式のオブジェクトに変換し、各要素を取り出し
      var mapObj = jsonDecode(jsonStr);

      var title = mapObj['title'];
      var state = mapObj['state'];
      cards.add(TodoCardWidget(
        label: title,
        state: state,
        number: cards.length,
      ));
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
                          return snapshot.data![index];
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
              cards.add(TodoCardWidget(
                label: resultLabel,
                state: false,
                number: cards.length,
              ));
              SharedPreferences.getInstance().then((prefs) async {
                var todo = prefs.getStringList("todo") ?? [];
                todo.add(jsonEncode({'title': resultLabel, 'state': false}));
                await prefs.setStringList("todo", todo);
              });
            });
          }
        },
      ),
    );
  }
}

class TodoCardWidget extends StatefulWidget {
  final String label;
  bool state;
  final int number;

  TodoCardWidget(
      {Key? key,
      required this.label,
      required this.state,
      required this.number})
      : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) {
    setState(() {
      widget.state = value ?? false;
    });
    SharedPreferences.getInstance().then((prefs) {
      var todo = prefs.getStringList("todo") ?? [];
      var jsonObj = jsonDecode(todo[widget.number]);
      jsonObj['state'] = value ?? false;
      todo[widget.number] = jsonEncode(jsonObj);
      prefs.setStringList("todo", todo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(onChanged: _changeState, value: widget.state),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}
