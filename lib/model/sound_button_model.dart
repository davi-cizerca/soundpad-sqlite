class SoundButtonModel {
  int? id;
  String nome;
  String audioPath;
  String? cor;
  String? categoria;

  SoundButtonModel({
    this.id,
    required this.nome,
    required this.audioPath,
    this.cor,
    this.categoria,
  });

  factory SoundButtonModel.fromMap(Map map) {
    return SoundButtonModel(
      id: map['id'],
      nome: map['nome'],
      audioPath: map['audioPath'],
      cor: map['cor'],
      categoria: map['categoria'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'audioPath': audioPath,
      'cor': cor,
      'categoria': categoria,
    };
  }

  @override
  String toString() {
    return 'SoundButtonModel: {id: $id, nome: $nome, audioPath: $audioPath, cor: $cor, categoria: $categoria}';
  }
}
