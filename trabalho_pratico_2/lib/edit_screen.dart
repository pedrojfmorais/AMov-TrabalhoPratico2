import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trabalho_pratico_2/main.dart';
import 'package:http/http.dart' as http;

import 'data.dart';

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

  bool _botaoAtivo = false;
  List<bool> _alterado = [false, false, false, false, false];
  List<bool> _diferenteOriginal = [false, false, false, false, false];

  late final TextEditingController _tecSopa = TextEditingController();
  late final TextEditingController _tecCarne = TextEditingController();
  late final TextEditingController _tecPeixe = TextEditingController();
  late final TextEditingController _tecVegetariano = TextEditingController();
  late final TextEditingController _tecSobremesa = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tecSopa.addListener(_tecSopaVerificaTexto);
    _tecCarne.addListener(_tecCarneVerificaTexto);
    _tecPeixe.addListener(_tecPeixeVerificaTexto);
    _tecVegetariano.addListener(_tecVegetarianoVerificaTexto);
    _tecSobremesa.addListener(_tecSobremesaVerificaTexto);
  }

  void _tecSopaVerificaTexto() {
    _verificaTexto(
        _tecSopa, diaSemana.original.soup, diaSemana.update!.soup, 0);
  }

  void _tecCarneVerificaTexto() {
    _verificaTexto(
        _tecCarne, diaSemana.original.meat, diaSemana.update!.meat, 1);
  }

  void _tecPeixeVerificaTexto() {
    _verificaTexto(
        _tecPeixe, diaSemana.original.fish, diaSemana.update!.fish, 2);
  }

  void _tecVegetarianoVerificaTexto() {
    _verificaTexto(_tecVegetariano, diaSemana.original.vegetarian,
        diaSemana.update!.vegetarian, 3);
  }

  void _tecSobremesaVerificaTexto() {
    _verificaTexto(
        _tecSobremesa, diaSemana.original.desert, diaSemana.update!.desert, 4);
  }

  void _verificaTexto(var tec, var original, var update, int indiceAtivo) {
    if (tec.text != original) {
      _diferenteOriginal[indiceAtivo] = true;
    } else {
      _diferenteOriginal[indiceAtivo] = false;
    }

    if (diaSemana.update != null) {
      if (tec.text != update) {
        _alterado[indiceAtivo] = true;
      } else {
        _alterado[indiceAtivo] = false;
      }
    } else {
      if (tec.text != original) {
        _alterado[indiceAtivo] = true;
      } else {
        _alterado[indiceAtivo] = false;
      }
    }

    setState(() {
      if (_alterado.contains(true)) {
        _botaoAtivo = true;
      } else {
        _botaoAtivo = false;
      }
      _diferenteOriginal;
    });
  }

  void _resetSopa() {
    _reset(_tecSopa, diaSemana.original.soup, diaSemana.update!.soup, 0);
  }

  void _resetCarne() {
    _reset(_tecCarne, diaSemana.original.meat, diaSemana.update!.meat, 1);
  }

  void _resetPeixe() {
    _reset(_tecPeixe, diaSemana.original.fish, diaSemana.update!.fish, 2);
  }

  void _resetVegetariano() {
    _reset(_tecVegetariano, diaSemana.original.vegetarian,
        diaSemana.update!.vegetarian, 3);
  }

  void _resetSobremesa() {
    _reset(
        _tecSobremesa, diaSemana.original.desert, diaSemana.update!.desert, 4);
  }

  void _reset(var tec, var original, var update, var indice) {
    tec.text = original;
    _verificaTexto(tec, original, update, indice);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (diaSemana.update != null &&
        diaSemana.original.soup != diaSemana.update!.soup) {
      _tecSopa.text = diaSemana.update!.soup!;
      _diferenteOriginal[0] = true;
    } else {
      _tecSopa.text = diaSemana.original.soup!;
    }
    if (diaSemana.update != null &&
        diaSemana.original.meat != diaSemana.update!.meat) {
      _tecCarne.text = diaSemana.update!.meat!;
      _diferenteOriginal[1] = true;
    } else {
      _tecCarne.text = diaSemana.original.meat!;
    }
    if (diaSemana.update != null &&
        diaSemana.original.fish != diaSemana.update!.fish) {
      _tecPeixe.text = diaSemana.update!.fish!;
      _diferenteOriginal[2] = true;
    } else {
      _tecPeixe.text = diaSemana.original.fish!;
    }
    if (diaSemana.update != null &&
        diaSemana.original.vegetarian != diaSemana.update!.vegetarian) {
      _tecVegetariano.text = diaSemana.update!.vegetarian!;
      _diferenteOriginal[3] = true;
    } else {
      _tecVegetariano.text = diaSemana.original.vegetarian!;
    }
    if (diaSemana.update != null &&
        diaSemana.original.desert != diaSemana.update!.desert) {
      _tecSobremesa.text = diaSemana.update!.desert!;
      _diferenteOriginal[4] = true;
    } else {
      _tecSobremesa.text = diaSemana.original.desert!;
    }
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

    return http
        .post(
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
        )
        .whenComplete(() => callback());
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Sopa:',
                                  hintText: 'O que é a sopa?',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _tecSopa),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                              onPressed:
                                  _diferenteOriginal[0] ? _resetSopa : null,
                              tooltip: 'Reset',
                              heroTag: "AMovTP2-reset-sopa",
                              backgroundColor: _diferenteOriginal[0]
                                  ? Theme.of(context).primaryColor
                                  : Colors.white24,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.cruelty_free),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              minLines: 2,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Prato de Carne:',
                                hintText: 'O que é o prato de carne?',
                                border: OutlineInputBorder(),
                              ),
                              controller: _tecCarne,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                              onPressed:
                                  _diferenteOriginal[1] ? _resetCarne : null,
                              tooltip: 'Reset',
                              heroTag: "AMovTP2-reset-carne",
                              backgroundColor: _diferenteOriginal[1]
                                  ? Theme.of(context).primaryColor
                                  : Colors.white24,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.set_meal),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              minLines: 2,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Prato de Peixe:',
                                hintText: 'O que é o prato de peixe?',
                                border: OutlineInputBorder(),
                              ),
                              controller: _tecPeixe,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                              onPressed:
                                  _diferenteOriginal[2] ? _resetPeixe : null,
                              tooltip: 'Reset',
                              heroTag: "AMovTP2-reset-peixe",
                              backgroundColor: _diferenteOriginal[2]
                                  ? Theme.of(context).primaryColor
                                  : Colors.white24,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.eco_rounded),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              minLines: 2,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Prato Vegetariano:',
                                hintText: 'O que é o prato vegetarioano?',
                                border: OutlineInputBorder(),
                              ),
                              controller: _tecVegetariano,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                              onPressed: _diferenteOriginal[3]
                                  ? _resetVegetariano
                                  : null,
                              tooltip: 'Reset',
                              heroTag: "AMovTP2-reset-vegetariano",
                              backgroundColor: _diferenteOriginal[3]
                                  ? Theme.of(context).primaryColor
                                  : Colors.white24,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.apple),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Sobremesa:',
                                hintText: 'O que é a sobremesa?',
                                border: OutlineInputBorder(),
                              ),
                              controller: _tecSobremesa,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                              onPressed: _diferenteOriginal[4]
                                  ? _resetSobremesa
                                  : null,
                              tooltip: 'Reset',
                              heroTag: "AMovTP2-reset-sobremesa",
                              backgroundColor: _diferenteOriginal[4]
                                  ? Theme.of(context).primaryColor
                                  : Colors.white24,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Hero(
                tag: "AMovTP2-atualizar",
                child: ElevatedButton(
                  onPressed: _botaoAtivo ? _updateEmenta : null,
                  child: const Text(
                    'Guardar Alterações',
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
