import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'edit_screen.dart';

void main() {
  runApp(const MyApp());
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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case MyHomePage.routeName:
            return PageTransition(
              child: const MyHomePage(title: 'Ementa Semanal'),
              type: PageTransitionType.fade,
            );
          case EditScreen.routeName:
            return PageTransition(
              child: const EditScreen(),
              type: PageTransitionType.rightToLeft,
              settings: settings,
            );
          default:
            return null;
        }
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
    _loadSharedPreferences();
  }

  Future<void> _loadSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    String? userPref = prefs.getString('diasSemanaEmenta');
    setState(() {
      if (userPref == null) {
        _diasSemanaEmenta = null;
      } else {
        _diasSemanaEmenta = [];
        List<dynamic> lista = jsonDecode(userPref);
        _diasSemanaEmenta =
            List<DiaSemana>.from(lista.map((e) => DiaSemana.fromJson(e, "")));

        for (int i = 1; i <= Constants.diasSemana.length; i++) {
          for (var diaSemana in _diasSemanaEmenta!) {
            if (diaSemana.original.weekDay == Constants.diasSemana[i]) {
              diaSemana.dia = Constants.diasSemanaPortugues[i]!;
              break;
            }
          }
        }

        _weekday = DateTime.now().weekday < 6 ? DateTime.now().weekday : 1;

        while (_diasSemanaEmenta!.first.dia !=
            Constants.diasSemanaPortugues[_weekday]) {
          _diasSemanaEmenta!.add(_diasSemanaEmenta!.removeAt(0));
        }
      }
    });
  }

  Future<void> _saveSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('diasSemanaEmenta', jsonEncode(_diasSemanaEmenta));
  }

  void getEmenta() {
    setState(() {
      _fetchEmenta();
    });
  }

  List<DiaSemana>? _diasSemanaEmenta = [];
  bool _fetchingData = false;
  double? _imageSize = 250;
  int _weekday = 1;

  Future<void> _fetchEmenta() async {
    try {
      setState(() => _fetchingData = true);
      setState(() => _imageSize = 50);
      http.Response response =
          await http.get(Uri.parse(Constants.ementaMenuUrl));
      if (response.statusCode == HttpStatus.ok) {
        final Map<String, dynamic> decodedData =
            json.decode(utf8.decode(response.bodyBytes));

        if (_diasSemanaEmenta != null) {
          _diasSemanaEmenta!.clear();
        } else {
          _diasSemanaEmenta = [];
        }

        for (int i = 1; i <= Constants.diasSemana.length; i++) {
          _diasSemanaEmenta!.add(DiaSemana.fromJson(
              decodedData[Constants.diasSemana[i]],
              Constants.diasSemanaPortugues[i]!));
        }

        _weekday = DateTime.now().weekday < 6 ? DateTime.now().weekday : 1;

        while (_diasSemanaEmenta!.first.dia !=
            Constants.diasSemanaPortugues[_weekday]) {
          _diasSemanaEmenta!.add(_diasSemanaEmenta!.removeAt(0));
        }

        setState(() => {_diasSemanaEmenta});
      }
    } catch (ex) {
      debugPrint('Something went wrong: $ex');
    } finally {
      setState(() => _fetchingData = false);
      setState(() => _imageSize = 250);
      _saveSharedPreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedContainer(
                  height: _imageSize,
                  width: _imageSize,
                  duration: const Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('resources/logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (_diasSemanaEmenta == null)
                const Text("Não existe informação guardada localmente!")
              else
                for (var diaSemana in _diasSemanaEmenta!)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          EditScreen.routeName,
                          arguments: ArgumentosEditScreen(diaSemana, getEmenta),
                        ),
                        child: Card(
                          color: Colors.lightGreen,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                if (diaSemana.dia ==
                                    Constants.diasSemanaPortugues[_weekday])
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.amber,
                                  ),
                                Text(
                                  diaSemana.dia,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                      fontSize: 24),
                                ),
                                const Icon(Icons.soup_kitchen),
                                if (diaSemana.update != null &&
                                    diaSemana.original.soup !=
                                        diaSemana.update!.soup)
                                  Text(
                                    diaSemana.update!.soup!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline),
                                  )
                                else
                                  Text(diaSemana.original.soup!),
                                const Icon(Icons.cruelty_free),
                                if (diaSemana.update != null &&
                                    diaSemana.original.meat !=
                                        diaSemana.update!.meat)
                                  Text(
                                    diaSemana.update!.meat!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline),
                                  )
                                else
                                  Text(diaSemana.original.meat!),
                                const Icon(Icons.set_meal),
                                if (diaSemana.update != null &&
                                    diaSemana.original.fish !=
                                        diaSemana.update!.fish)
                                  Text(
                                    diaSemana.update!.fish!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline),
                                  )
                                else
                                  Text(diaSemana.original.fish!),
                                const Icon(Icons.eco_rounded),
                                if (diaSemana.update != null &&
                                    diaSemana.original.vegetarian !=
                                        diaSemana.update!.vegetarian)
                                  Text(
                                    diaSemana.update!.vegetarian!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline),
                                  )
                                else
                                  Text(diaSemana.original.vegetarian!),
                                const Icon(Icons.apple),
                                if (diaSemana.update != null &&
                                    diaSemana.original.desert !=
                                        diaSemana.update!.desert)
                                  Text(
                                    diaSemana.update!.desert!,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline),
                                  )
                                else
                                  Text(diaSemana.original.desert!),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getEmenta,
        tooltip: 'Refresh',
        heroTag: "AMovTP2-refresh",
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
