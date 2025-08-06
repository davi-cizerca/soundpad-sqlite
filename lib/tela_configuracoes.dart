import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'theme_manager.dart';

class TelaConfiguracoes extends StatefulWidget {
  final ThemeManager themeManager;

  const TelaConfiguracoes({Key? key, required this.themeManager})
    : super(key: key);

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  ThemeMode _selectedThemeMode = ThemeMode.system;
  Color _selectedButtonColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.themeManager.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Tema
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema do Aplicativo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildThemeOption(
                      ThemeMode.system,
                      'Sistema',
                      'Segue as configurações do dispositivo',
                      Icons.brightness_auto,
                    ),
                    _buildThemeOption(
                      ThemeMode.light,
                      'Claro',
                      'Tema claro',
                      Icons.light_mode,
                    ),
                    _buildThemeOption(
                      ThemeMode.dark,
                      'Escuro',
                      'Tema escuro',
                      Icons.dark_mode,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Seção de Cores dos Botões
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cor Padrão dos Botões',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildColorPicker(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Seção de Compartilhamento
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.share, color: Colors.indigo),
                      title: Text(
                        'Compartilhar Áudio',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Compartilhe áudios diretamente do app',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showShareOptions,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Seção de Informações
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre o App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: Colors.blue),
                      title: Text(
                        'Versão',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '1.3.0',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.description, color: Colors.green),
                      title: Text(
                        'Licença',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'MIT License',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedThemeMode == mode;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (isDark
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.indigo.withOpacity(0.1))
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.indigo, width: 2) : null,
      ),
      child: RadioListTile<ThemeMode>(
        value: mode,
        groupValue: _selectedThemeMode,
        onChanged: (ThemeMode? value) {
          if (value != null) {
            setState(() {
              _selectedThemeMode = value;
            });
            widget.themeManager.setThemeMode(value);
          }
        },
        title: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Colors.indigo
                      : (isDark ? Colors.white70 : Colors.black54),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: Colors.indigo,
      ),
    );
  }

  Widget _buildColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione a cor padrão para novos botões:',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              colors.map((color) {
                final isSelected = _selectedButtonColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedButtonColor = color;
                    });
                    // Aqui você pode salvar a cor selecionada
                    _saveButtonColor(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color: _getContrastColor(color),
                              size: 20,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _saveButtonColor(Color color) {
    // Implementar salvamento da cor no SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cor padrão alterada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Compartilhar Áudio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Selecionar arquivo de áudio'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareAudioFile();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.mic),
                  title: Text('Compartilhar gravação recente'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareRecentRecording();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _shareAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Compartilhando áudio via SoundPad');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arquivo não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareRecentRecording() async {
    try {
      // Procurar por arquivos de áudio recentes no diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final files =
          directory
              .listSync()
              .where(
                (file) =>
                    file is File &&
                    (file.path.endsWith('.aac') ||
                        file.path.endsWith('.m4a') ||
                        file.path.endsWith('.mp3') ||
                        file.path.endsWith('.wav')),
              )
              .cast<File>()
              .toList();

      if (files.isNotEmpty) {
        // Pegar o arquivo mais recente
        files.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
        );
        final recentFile = files.first;

        await Share.shareXFiles([
          XFile(recentFile.path),
        ], text: 'Gravação recente do SoundPad');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nenhuma gravação encontrada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar gravação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
