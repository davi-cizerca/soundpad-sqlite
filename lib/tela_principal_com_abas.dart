import 'package:flutter/material.dart';
import 'tela_inicial_soundpad.dart';
import 'tela_gravacao_audio.dart';

class TelaPrincipalComAbas extends StatefulWidget {
  const TelaPrincipalComAbas({super.key});

  @override
  State<TelaPrincipalComAbas> createState() => _TelaPrincipalComAbasState();
}

class _TelaPrincipalComAbasState extends State<TelaPrincipalComAbas> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [TelaInicialSoundpad(), TelaGravacaoAudio()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'SoundPad',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Gravar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
