import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trabalho_pratico_2/main.dart';
import 'package:http/http.dart' as http;

class EditScreen extends StatefulWidget {
  const EditScreen({Key? key}) : super(key: key);

  static const String routeName = 'EditScreen';

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {

  late final ArgumentosEditScreen args =
      ModalRoute.of(context)!.settings.arguments as ArgumentosEditScreen;

  late final DiaSemana diaSemana = args.diaSemana;
  late final Function callback = args.callback;

  // Ementa alteracoes = Ementa.empty();

  late final TextEditingController _tecSopa = TextEditingController();
  late final TextEditingController _tecCarne = TextEditingController();
  late final TextEditingController _tecPeixe = TextEditingController();
  late final TextEditingController _tecVegetariano = TextEditingController();
  late final TextEditingController _tecSobremesa = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (diaSemana.update != null &&
        diaSemana.original.meat != diaSemana.update!.meat) {
      _tecSopa.text = diaSemana.update!.meat!;
    } else {
      _tecSopa.text = diaSemana.original.meat!;
    }

    _tecSopa.text = diaSemana.original.soup!;
    _tecCarne.text = diaSemana.original.meat!;
    _tecPeixe.text = diaSemana.original.fish!;
    _tecVegetariano.text = diaSemana.original.vegetarian!;
    _tecSobremesa.text = diaSemana.original.desert!;
  }

  @override
  void dispose() {
    super.dispose();
    _tecSopa.dispose();
    _tecCarne.dispose();
    _tecPeixe.dispose();
    _tecVegetariano.dispose();
    _tecSobremesa.dispose();
  }

  Future<http.Response> _updateEmenta() {

    Navigator.pop(context);

    return http.post(
      Uri.parse(Constants.ementaMenuUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(Ementa(
          diaSemana.original.img,
          diaSemana.original.weekDay,
          _tecSopa.text,
          _tecPeixe.text,
          _tecCarne.text,
          _tecVegetariano.text,
          _tecSobremesa.text)),
    ).whenComplete(() => callback());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar menu',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.lightGreen,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        diaSemana.dia,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: 24),
                      ),
                      const Icon(Icons.soup_kitchen),
                      TextFormField(
                          minLines: 2,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Sopa:',
                            hintText: 'O que é a sopa?',
                            border: OutlineInputBorder(),
                          ),
                          controller: _tecSopa),
                      const Icon(Icons.cruelty_free),
                      TextFormField(
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Prato de Carne:',
                          hintText: 'O que é o prato de carne?',
                          border: OutlineInputBorder(),
                        ),
                        controller: _tecCarne,
                      ),
                      const Icon(Icons.set_meal),
                      TextFormField(
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Prato de Peixe:',
                          hintText: 'O que é o prato de peixe?',
                          border: OutlineInputBorder(),
                        ),
                        controller: _tecPeixe,
                      ),
                      const Icon(Icons.eco_rounded),
                      TextFormField(
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Prato Vegetariano:',
                          hintText: 'O que é o prato vegetarioano?',
                          border: OutlineInputBorder(),
                        ),
                        controller: _tecVegetariano,
                      ),
                      const Icon(Icons.apple),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Sobremesa:',
                          hintText: 'O que é a sobremesa?',
                          border: OutlineInputBorder(),
                        ),
                        controller: _tecSobremesa,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _updateEmenta,
                child: const Text(
                  'Guardar Alterações',
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
