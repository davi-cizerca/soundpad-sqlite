
class DogModel {
  int? id;
  String Nome;
  int Idade;

  DogModel({
    this.id,
    required this.Nome,
    required this.Idade,
  });

  factory DogModel.fromMap(Map map) {
    return DogModel(
      id: map['id'],
      Nome: map['nome'],
      Idade: map['idade'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'nome': Nome,
      'idade': Idade, 
    };
  }
  // O método toMap é utilizado para converter o objeto DogModel em um mapa

  @override
  String toString() {
    return 'DogModel: {id: $id, Nome: $Nome, Idade: $Idade}';
  }
}

