import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

class Constants {
  static const Map<int, String> diasSemana = {
    1: 'MONDAY',
    2: 'TUESDAY',
    3: 'WEDNESDAY',
    4: 'THURSDAY',
    5: 'FRIDAY'
  };

  static const Map<int, String> diasSemanaPortugues = {
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira'
  };

  static const String server = '192.168.1.39:8080';
  static const String ementaMenuUrl = 'http://$server/menu';
  static const String ementaImageUrl = 'http://$server/images/';
}

class Ementa {
  Ementa.fromJson(Map<String, dynamic> json)
      : img = json['img'],
        imageBytes = null,
        weekDay = json['weekDay'],
        soup = json['soup'],
        fish = json['fish'],
        meat = json['meat'],
        vegetarian = json['vegetarian'],
        desert = json['desert'];

  Map<String, dynamic> toJson() {
    return {
      'img': img,
      'weekDay': weekDay,
      'soup': soup,
      'fish': fish,
      'meat': meat,
      'vegetarian': vegetarian,
      'desert': desert,
    };
  }

  Ementa(this.img, this.imageBytes, this.weekDay, this.soup, this.fish,
      this.meat, this.vegetarian, this.desert);

  late String? img;
  late String? imageBytes;
  late String? weekDay;
  late String? soup;
  late String? fish;
  late String? meat;
  late String? vegetarian;
  late String? desert;
}

class DiaSemana {
  DiaSemana.fromJson(Map<String, dynamic> json, this.dia)
      : original = Ementa.fromJson(json['original']),
        update =
            json['update'] == null ? null : Ementa.fromJson(json['update']);

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'original': original,
      'update': update,
    };
  }

  String dia;
  final Ementa original;
  Ementa? update;
}

class ArgumentosEditScreen {
  ArgumentosEditScreen(this.diaSemana, this.callback);

  DiaSemana diaSemana;
  Function callback;
}

late List<CameraDescription> myAvailableCameras;

///HTTP Get da imagem
Future<String?> getImageHttp(String nomeImagem) async {
  http.Response response =
      await http.get(Uri.parse(Constants.ementaImageUrl + nomeImagem));
  if (response.statusCode == HttpStatus.ok) {
    return String.fromCharCodes(response.bodyBytes);
  }
  return null;
}
