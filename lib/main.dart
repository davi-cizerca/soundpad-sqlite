import 'package:flutter/material.dart';
import 'dart:io';
import 'package:testesqlite/dao/dogdao.dart';
import 'package:testesqlite/model/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'tela_inicial_soundpad.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();

  //Imprime as ocorrências do banco de dados
  debugPrint('Buscando todos os dogs...');
  findAll().then((dados) {
    for (Map<dynamic, dynamic> item in dados) {
      debugPrint('Item: $item');
    }
  });

  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: TelaInicialSoundpad()),
  );
}

class InicialShow extends StatefulWidget {
  @override
  State<InicialShow> createState() => _InicialShowState();
}

class _InicialShowState extends State<InicialShow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        leading: Icon(Icons.pets, color: Colors.white, size: 40.0),
        title: Text('Lista dos Dog', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        initialData: [],
        future: findAll(),
        builder: (context, snapshot) {
          // Snapshot ==> Variável que vai guardar os retornos da função Future
          // Snapshot ==>
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Center(child: CircularProgressIndicator());

            case ConnectionState.none:
              return Text('Nenhuma conexão estabelecida');

            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar dogs'));
              }
              List<Map> dogs = snapshot.data as List<Map>;
              if (dogs.isEmpty) {
                return Center(child: Text('Nenhum dog encontrado'));
              }
              return ListView.builder(
                itemCount: dogs.length,
                itemBuilder: (context, index) {
                  DogModel dog = DogModel.fromMap(dogs[index]);

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Card(
                        color: Colors.indigo.shade50,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListTile(
                          title: Text(dog.Nome),
                          subtitle: Text('Idade: ${dog.Idade.toString()}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (dog.id != null) {
                                await removeDog(dog.id!);
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TelaCadastroShow()),
          ).then((p) {
            if (p != null) {
              setState(() {});
            }
          });
        },
        backgroundColor: Colors.indigo.shade600, // Cor do botão
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

class TelaCadastroShow extends StatelessWidget {
  final TextEditingController _controllernome =
      TextEditingController(); // Controlador de texto para o nome
  final TextEditingController _controlleridade =
      TextEditingController(); // Controlador de texto para a idade

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.abc, size: 40),
            color: Colors.white,
          ),
        ],
        title: Text("Cadastro de Dogs", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 40),
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 250,
                child: TextField(
                  controller: _controllernome,
                  decoration: InputDecoration(
                    labelText: 'Nome do Dog',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 250,
                child: TextField(
                  controller: _controlleridade,
                  decoration: InputDecoration(
                    labelText: 'Idade do Dog',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //-----------------------------------Limpar-----------------------------------
                  ElevatedButton(
                    onPressed: () {
                      _controllernome.text = "";
                      _controlleridade.text = "";
                    },
                    child: Text("Limpar"),
                  ),
                  SizedBox(width: 20),
                  //-------------------------------SALVAR------------------------
                  ElevatedButton(
                    onPressed: () async {
                      if (_controllernome.text == "" ||
                          _controlleridade.text == "") {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Campos obrigatórios'),
                                content: Text(
                                  'Por favor, preencha todos os campos.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                        );
                        return;
                      }
                      int? idade = int.tryParse(_controlleridade.text);
                      if (idade == null) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Idade inválida'),
                                content: Text(
                                  'Por favor, digite um número inteiro para a idade.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                        );
                        return;
                      }

                      DogModel p = DogModel(
                        Nome: _controllernome.text,
                        Idade: idade,
                      );
                      await insertDog(p);
                      Navigator.pop(context, p);
                    },
                    child: Text("Salvar"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
