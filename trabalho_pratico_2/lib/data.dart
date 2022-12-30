
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

  static const String ementaMenuUrl = 'http://192.168.1.39:8080/menu';
  static const String ementaImageUrl = 'http://192.168.1.39:8080/images/';
}

class Ementa {
  Ementa.fromJson(Map<String, dynamic> json)
      : img = json['img'],
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

  Ementa(this.img, this.weekDay, this.soup, this.fish, this.meat,
      this.vegetarian, this.desert);

  final String? img;
  final String? weekDay;
  final String? soup;
  final String? fish;
  final String? meat;
  final String? vegetarian;
  final String? desert;
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
  final Ementa? update;
}