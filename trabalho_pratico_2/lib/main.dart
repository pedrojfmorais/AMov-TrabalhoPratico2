import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'edit_screen.dart';

void main() {
  runApp(const MyApp());
}

const Map<int, String> diasSemana = {
  1: "MONDAY",
  2: "TUESDAY",
  3: "WEDNESDAY",
  4: "THURSDAY",
  5: "FRIDAY"
};

const String _ementaUrl = 'http://127.0.0.1:8080';
const String _menu = "/menu";
const String _image = "/images/";

class Ementa {
  Ementa.fromJson(Map<String, dynamic> json)
      : img = json['img'],
        weekDay = json['weekDay'],
        soup = json['soup'],
        fish = json['fish'],
        meat = json['meat'],
        vegetarian = json['vegetarian'],
        desert = json['desert'];

  final String? img;
  final String weekDay;
  final String soup;
  final String fish;
  final String meat;
  final String vegetarian;
  final String desert;
}

class DiaSemana {
  DiaSemana.fromJson(Map<String, dynamic> json, this.dia)
      : original = Ementa.fromJson(json['original']),
        update =
            json['update'] == null ? null : Ementa.fromJson(json['update']);

  final String dia;
  final Ementa original;
  final Ementa? update;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ementa',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      initialRoute: MyHomePage.routeName,
      routes: {
        MyHomePage.routeName: (context) =>
            const MyHomePage(title: 'Ementa Semanal'),
        EditScreen.routeName: (context) => const EditScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  static const String routeName = '/';

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    _getEmenta();
  }

  void _getEmenta() {
    setState(() {
      _fetchEmenta();
    });

  }

  final List<DiaSemana>? _diasSemanaEmenta = [];
  bool _fetchingData = false;

  Future<void> _fetchEmenta() async {
    try {
      setState(() => _fetchingData = true);
      http.Response response = await http.get(Uri.parse(_ementaUrl+_menu));
      if (response.statusCode == HttpStatus.ok) {
        final Map<String, dynamic> decodedData = json.decode(response.body);

        _diasSemanaEmenta!.clear();

        int weekday = DateTime.now().weekday;

        for (var diaSemana in diasSemana.values) {
          _diasSemanaEmenta!
              .add(DiaSemana.fromJson(decodedData[diaSemana], diaSemana));
        }

        while (_diasSemanaEmenta!.first.dia != diasSemana[weekday]) {
          _diasSemanaEmenta!.add(_diasSemanaEmenta!.removeAt(0));
        }

        setState(() => {_diasSemanaEmenta});
      }
    } catch (ex) {
      debugPrint('Something went wrong: $ex');
    } finally {
      setState(() => _fetchingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var diaSemana in _diasSemanaEmenta!)
              SizedBox(
                width: 1500,
                child: Card(
                  color: Colors.green,
                  child: Column(
                    children: [
                      Text(diaSemana.dia),
                      Text(diaSemana.original.soup),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getEmenta,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
