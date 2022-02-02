import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:todo/models/place.dart';

import 'package:todo/src/screens/location_insert.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map> cards = [];

  final _textFieldController = TextEditingController();
  final _locFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCards();
  }

  void _getCards() {
    SharedPreferences.getInstance().then((prefs) {
      var todo = prefs.getStringList("todo") ?? [];
      for (var jsonStr in todo) {
        setState(() {
          cards.add(jsonDecode(jsonStr));
        });
      }
    });
  }

  Future<Place?> _showLocationSelect(BuildContext context) async {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const LocationInsert();
    }));
  }

  Future<Map<String, dynamic>?> _showTextInputDialog(
      BuildContext context) async {
    Place? newLoc;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タイトル'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "文字列を入力してください。"),
            ),
            TextField(
                controller: _locFieldController,
                readOnly: true,
                decoration: const InputDecoration(hintText: "場所を入力してください。"),
                onTap: () async {
                  _showLocationSelect(context).then((value) {
                    _locFieldController.text = value!.name;
                    newLoc = value;
                  });
                })
          ]),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context, {
                  "state": false,
                  "title": _textFieldController.text,
                  "place": newLoc == null
                      ? null
                      : {
                          "name": newLoc!.name,
                          "vicinity": newLoc!.vicinity,
                          "geometry": {
                            "location": {
                              "lat": newLoc!.geometry.location.lat,
                              "lng": newLoc!.geometry.location.lng
                            }
                          }
                        }
                });
                _textFieldController.clear();
                _locFieldController.clear();
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
                    SharedPreferences.getInstance().then((prefs) async {
                      var todo = prefs.getStringList("todo") ?? [];
                      todo[index] = jsonEncode(cards[index]);
                      await prefs.setStringList("todo", todo);
                    });
                  });
                },
                value: cards[index]['state']),
            Text(cards[index]['title']),
            if (cards[index]['place'] != null) Icon(Icons.place)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todo App"),
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
              icon: const Icon(Icons.delete)),
        ],
      ),
      body: Center(
          child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (BuildContext context, int index) {
                return Dismissible(
                    key: ValueKey<String>(cards[index]['title']),
                    child: _todoWidget(index),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                          padding: const EdgeInsets.only(right: 10),
                          color: Colors.redAccent,
                          child: const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete))),
                    ),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        cards.removeAt(index);
                        SharedPreferences.getInstance().then((prefs) async {
                          var todo = prefs.getStringList("todo") ?? [];
                          todo.removeAt(index);
                          await prefs.setStringList("todo", todo);
                        });
                      });
                    });
              })),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null && resultLabel["title"] != "") {
            setState(() {
              cards.add(resultLabel);
              SharedPreferences.getInstance().then((prefs) async {
                var todo = prefs.getStringList("todo") ?? [];
                todo.add(jsonEncode(resultLabel));
                await prefs.setStringList("todo", todo);
              });
            });
          }
        },
      ),
    );
  }
}
