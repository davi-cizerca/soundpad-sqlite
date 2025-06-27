import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'dao/sound_button_dao.dart';
import 'model/sound_button_model.dart';
import 'tela_cadastro_sound_button.dart';

class TelaInicialSoundpad extends StatefulWidget {
  const TelaInicialSoundpad({super.key});

  @override
  State<TelaInicialSoundpad> createState() => _TelaInicialSoundpadState();
}

class _TelaInicialSoundpadState extends State<TelaInicialSoundpad> {
  List<SoundButtonModel> buttons = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final data = await findAllSoundButtons();
    setState(() {
      buttons = data.map((e) => SoundButtonModel.fromMap(e)).toList();
    });
  }

  void _playSound(String path) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
  }

  void _deleteButton(int id) async {
    await removeSoundButton(id);
    _loadButtons();
  }

  void _addOrEditButton([SoundButtonModel? button]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroSoundButton(button: button),
      ),
    );
    _loadButtons();
  }

  void _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Áudio selecionado: $path')));
      // Aqui você pode adicionar lógica para usar o arquivo selecionado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SoundPad'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Créditos',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Créditos'),
                  content: Text('Este aplicativo foi desenvolvido por Davi Cizerça para a matéria de Desenvolvimento para Dispositivos Móveis do professor Heitor Scalco Neto.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            final btn = buttons[index];
            return GestureDetector(
              onTap: () => _playSound(btn.audioPath),
              onLongPress: () => _addOrEditButton(btn),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      btn.cor != null
                          ? Color(int.parse(btn.cor!))
                          : Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        btn.nome,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteButton(btn.id!),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditButton(),
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
