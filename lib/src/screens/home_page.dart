import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map> cards = [];

  final _textFieldController = TextEditingController();

  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  Future<LocationData>? _locationData;

  @override
  void initState() {
    super.initState();
    _getCards();
    _accessLocation();
  }

  void _accessLocation() {
    Location location = Location();
    location.serviceEnabled().then((value) async {
      _serviceEnabled = value;
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      _locationData = location.getLocation();
    });
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

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タイトル'),
          content: Column(children: [
            TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "文字列を入力してください。"),
            ),
          ]),
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
                    SharedPreferences.getInstance().then((prefs) async {
                      var todo = prefs.getStringList("todo") ?? [];
                      todo[index] = jsonEncode(cards[index]);
                      await prefs.setStringList("todo", todo);
                    });
                  });
                },
                value: cards[index]['state']),
            Text(cards[index]['title']),
          ],
        ),
      ),
    );
  }

  void _toMap() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Map")),
        body: Center(
          child: FutureBuilder(
            future: _locationData,
            builder: (
              BuildContext context,
              AsyncSnapshot<LocationData> snapshot,
            ) {
              if (snapshot.hasData) {
                var loc = snapshot.data;
                return FlutterMap(
                  options: MapOptions(
                      center: (loc != null)
                          ? LatLng(loc.latitude!, loc.longitude!)
                          : LatLng(0, 0),
                      zoom: 18.0),
                  layers: [
                    TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      attributionBuilder: (_) =>
                          const Text("© OpenStreetMap contributors"),
                    ),
                    MarkerLayerOptions(markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: (loc != null)
                            ? LatLng(loc.latitude!, loc.longitude!)
                            : LatLng(0, 0),
                        builder: (ctx) => const Icon(Icons.location_pin),
                      )
                    ]),
                  ],
                );
              }
              return const Text("地図をロード中");
            },
          ),
        ),
      );
    }));
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
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _toMap,
          )
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
