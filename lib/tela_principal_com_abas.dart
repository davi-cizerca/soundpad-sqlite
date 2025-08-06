import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tela_inicial_soundpad.dart';
import 'tela_configuracoes.dart';
import 'theme_manager.dart';

class TelaPrincipalComAbas extends StatefulWidget {
  const TelaPrincipalComAbas({super.key});

  @override
  State<TelaPrincipalComAbas> createState() => _TelaPrincipalComAbasState();
}

class _TelaPrincipalComAbasState extends State<TelaPrincipalComAbas> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    final List<Widget> pages = [
      TelaInicialSoundpad(),
      TelaConfiguracoes(themeManager: themeManager),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'SoundPad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: onItemTapped,
      ),
    );
  }
}
