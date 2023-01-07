import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trabalho_pratico_2/camera.dart';

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
        textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.1,
              fontSizeDelta: 2.0,
            ),
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
          case CameraPage.routeName:
            return PageTransition(
              child: CameraPage(),
              type: PageTransitionType.bottomToTop,
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
  late CameraController controller;

  List<DiaSemana>? _diasSemanaEmenta = [];
  bool _fetchingData = false;
  double? _imageSize = 250;
  int _weekday = 1;

  Location location = Location();

  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  late LocationData _locationData;

  bool _podeEditar = false;

  @override
  void initState() {
    super.initState();

    _loadSharedPreferences();
    _getAvailableCameras();
    _initLocation();
  }

  @override
  void dispose() {
    super.dispose();

    controller.dispose();
  }

  /// Inicializar localização
  Future<void> _initLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    setState(() => {});

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    setState(() {
      _podeEditar = (((_locationData.latitude! - Constants.latitudeIsec) < 1 ||
              (_locationData.latitude! - Constants.latitudeIsec) > 1) &&
          ((_locationData.longitude! - Constants.longitudeIsec) < 1 ||
              (_locationData.longitude! - Constants.longitudeIsec) > 1));
    });
  }

  Future<void> _getCoordinates() async {
    if (_permissionGranted != PermissionStatus.granted &&
        _permissionGranted != PermissionStatus.deniedForever) {
      _permissionGranted = await location.requestPermission();
    }

    setState(() { });

    if (!_serviceEnabled || _permissionGranted != PermissionStatus.granted) {
      return;
    }

    _locationData = await location.getLocation();

    setState(() {
      _podeEditar = (((_locationData.latitude! - Constants.latitudeIsec) < 1 ||
              (_locationData.latitude! - Constants.latitudeIsec) > 1) &&
          ((_locationData.longitude! - Constants.longitudeIsec) < 1 ||
              (_locationData.longitude! - Constants.longitudeIsec) > 1));
    });
  }

  /// Ir buscar cameras disponiveis
  Future<void> _getAvailableCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    myAvailableCameras = await availableCameras();
    _initCamera(myAvailableCameras.first);
  }

  /// Inicialização camera
  Future<void> _initCamera(CameraDescription description) async {
    controller =
        CameraController(description, ResolutionPreset.max, enableAudio: true);

    try {
      await controller.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Something went wrong: $e');
    }
  }

  /// Carregar Shared Preferences
  Future<void> _loadSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    String? userPref = prefs.getString(Constants.sharedPreferencesValueName);

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

      for (var diaSemana in _diasSemanaEmenta!) {
        //Valor default e para não dar uma exceção devido às funções assincronas
        diaSemana.original.imageBytes = null;

        if (diaSemana.update != null && diaSemana.update!.img != null) {
          diaSemana.original.imageBytes =
              await getImageHttp(diaSemana.update!.img!);
        } else if (diaSemana.original.img != null) {
          diaSemana.original.imageBytes =
              await getImageHttp(diaSemana.original.img!);
        }
      }
    }
    setState(() {
      _diasSemanaEmenta;
    });
  }

  /// Guardar na shared preferences
  Future<void> _saveSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(
        Constants.sharedPreferencesValueName, jsonEncode(_diasSemanaEmenta));
  }

  ///Função ir buscar ementas
  void getEmenta() {
    setState(() {
      _fetchEmenta();
    });
  }

  /// HTTP Get para as ementas
  Future<void> _fetchEmenta() async {
    try {
      setState(() {
        _imageSize = 50;
        _fetchingData = true;
      });
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

        for (var diaSemana in _diasSemanaEmenta!) {
          if (diaSemana.update != null && diaSemana.update!.img != null) {
            diaSemana.original.imageBytes =
                await getImageHttp(diaSemana.update!.img!);
          } else if (diaSemana.original.img != null) {
            diaSemana.original.imageBytes =
                await getImageHttp(diaSemana.original.img!);
          } else {
            diaSemana.original.imageBytes = null;
          }
          diaSemana.update ??= diaSemana.original;
        }

        setState(() => {_diasSemanaEmenta});
      }
    } catch (ex) {
      debugPrint('Something went wrong: $ex');
    } finally {
      setState(() {
        _imageSize = 250;
        _fetchingData = false;
      });
      _saveSharedPreferences();
    }
  }

  Widget _ementasWidget(BuildContext context) {
    return Column(
      children: [
        if (_diasSemanaEmenta == null)
          const Text("Não existe informação guardada localmente!")
        else
          for (var diaSemana in _diasSemanaEmenta!)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    if (_podeEditar) {
                      Navigator.pushNamed(
                        context,
                        EditScreen.routeName,
                        arguments: ArgumentosEditScreen(diaSemana, getEmenta),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Encontra-se muito longe da cantina')));
                    }
                  },
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
                          if (diaSemana.original.imageBytes != null)
                            Image.memory(
                              Uint8List.fromList(
                                  diaSemana.original.imageBytes!.codeUnits),
                              height: 100,
                            ),
                          const Icon(Icons.soup_kitchen),
                          if (diaSemana.update != null &&
                              diaSemana.original.soup != diaSemana.update!.soup)
                            Text(
                              diaSemana.update!.soup!,
                              style: const TextStyle(
                                  decoration: TextDecoration.underline),
                            )
                          else
                            Text(diaSemana.original.soup!),
                          const Icon(Icons.cruelty_free),
                          if (diaSemana.update != null &&
                              diaSemana.original.meat != diaSemana.update!.meat)
                            Text(
                              diaSemana.update!.meat!,
                              style: const TextStyle(
                                  decoration: TextDecoration.underline),
                            )
                          else
                            Text(diaSemana.original.meat!),
                          const Icon(Icons.set_meal),
                          if (diaSemana.update != null &&
                              diaSemana.original.fish != diaSemana.update!.fish)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              _ementasWidget(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _fetchingData
          ? const CircularProgressIndicator(
              backgroundColor: Colors.white,
            )
          : FloatingActionButton(
              onPressed: () {
                getEmenta();
                _getCoordinates();

                if (!_serviceEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Serviço de localização não disponivel')));
                }

                if (_permissionGranted != PermissionStatus.granted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Não foram dadas permissões de localização')));
                }
              },
              tooltip: 'Refresh',
              heroTag: "AMovTP2-refresh",
              child: const Icon(Icons.refresh),
            ),
    );
  }
}
