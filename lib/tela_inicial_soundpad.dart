import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
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
  List<SoundButtonModel> filteredButtons = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  SoundButtonModel? _currentlyPlaying;
  String? _selectedCategory;
  List<String> categories = [];

  List<SoundButtonModel> _recentSounds = [];

  @override
  void initState() {
    super.initState();
    _loadButtons();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _currentlyPlaying = null;
      });
    });
  }

  Future<void> _loadButtons() async {
    final data = await findAllSoundButtons();
    final categoriesData = await findAllCategories();
    setState(() {
      buttons = data.map((e) => SoundButtonModel.fromMap(e)).toList();
      categories = categoriesData;
      _filterButtons();
    });
  }

  void _filterButtons() {
    if (_selectedCategory == null) {
      filteredButtons = buttons;
    } else {
      filteredButtons =
          buttons.where((btn) => btn.categoria == _selectedCategory).toList();
    }
  }

  void _addToRecent(SoundButtonModel btn) {
    setState(() {
      _recentSounds.removeWhere((b) => b.id == btn.id);
      _recentSounds.insert(0, btn);
      if (_recentSounds.length > 10) {
        _recentSounds = _recentSounds.sublist(0, 10);
      }
    });
  }

  void _playSound(String path, [SoundButtonModel? btn]) async {
    try {
      if (_currentlyPlaying?.id == btn?.id) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlaying = null;
        });
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() {
          _currentlyPlaying = btn;
        });
        if (btn != null) {
          _addToRecent(btn);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reproduzir áudio: $e')));
    }
  }

  void _deleteButton(int id) async {
    await removeSoundButton(id);
    _loadButtons();
    setState(() {
      _recentSounds.removeWhere((b) => b.id == id);
      if (_currentlyPlaying?.id == id) {
        _currentlyPlaying = null;
      }
    });
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
    }
  }

  void _showRecentSoundsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recentes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              if (_recentSounds.isEmpty)
                Text('Nenhum som tocado recentemente.')
              else
                ..._recentSounds.map(
                  (btn) => ListTile(
                    leading: Icon(
                      _currentlyPlaying?.id == btn.id
                          ? Icons.pause
                          : Icons.play_arrow,
                      color:
                          _currentlyPlaying?.id == btn.id
                              ? Colors.red
                              : Colors.indigo,
                    ),
                    title: Text(btn.nome),
                    subtitle:
                        _currentlyPlaying?.id == btn.id
                            ? Text(
                              'Reproduzindo...',
                              style: TextStyle(color: Colors.red),
                            )
                            : null,
                    trailing: PopupMenuButton<String>(
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'play',
                              child: Text('Reproduzir'),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: Text('Compartilhar'),
                            ),
                          ],
                      onSelected: (value) {
                        if (value == 'play') {
                          _playSound(btn.audioPath, btn);
                        } else if (value == 'share') {
                          _shareAudio(btn);
                        }
                      },
                    ),
                    onTap: () => _playSound(btn.audioPath, btn),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _shareAudio(SoundButtonModel sound) async {
    try {
      if (sound.audioPath != null) {
        final file = File(sound.audioPath!);
        if (await file.exists()) {
          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Compartilhando: ${sound.nome}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arquivo de áudio não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nenhum arquivo de áudio associado'),
            backgroundColor: Colors.orange,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SoundPad'),
        backgroundColor: Colors.indigo,
        actions: [
          if (categories.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list),
              tooltip: 'Filtrar por categoria',
              onSelected: (String category) {
                setState(() {
                  _selectedCategory = category == 'Todas' ? null : category;
                  _filterButtons();
                });
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Todas',
                    child: Text('Todas as categorias'),
                  ),
                  ...categories
                      .map(
                        (category) => PopupMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                ];
              },
            ),
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Recentes',
            onPressed: _showRecentSoundsModal,
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Créditos',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Créditos'),
                      content: Text(
                        'Este aplicativo foi desenvolvido por Davi Cizerça para a matéria de Desenvolvimento para Dispositivos Móveis do professor Heitor Scalco Neto.',
                      ),
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
      body: Column(
        children: [
          if (_currentlyPlaying != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.green.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reproduzindo:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          _currentlyPlaying!.nome,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.stop),
                    color: Colors.green.shade700,
                    onPressed:
                        () => _playSound(
                          _currentlyPlaying!.audioPath,
                          _currentlyPlaying,
                        ),
                    tooltip: 'Parar reprodução',
                  ),
                ],
              ),
            ),

          if (_selectedCategory != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: Colors.blue.shade700, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Categoria: $_selectedCategory',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _filterButtons();
                      });
                    },
                    child: Text(
                      'Limpar filtro',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  filteredButtons.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum som cadastrado',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toque no + para adicionar seu primeiro som',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredButtons.length,
                        itemBuilder: (context, index) {
                          final btn = filteredButtons[index];
                          final isPlaying = _currentlyPlaying?.id == btn.id;

                          return GestureDetector(
                            onTap: () => _playSound(btn.audioPath, btn),
                            onLongPress: () async {
                              // Excluir ao segurar por 1 segundo
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Excluir'),
                                      content: Text(
                                        'Deseja excluir o som "${btn.nome}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('Excluir'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                _deleteButton(btn.id!);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    btn.cor != null
                                        ? Color(int.parse(btn.cor!))
                                        : Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isPlaying
                                        ? Border.all(
                                          color: Colors.green,
                                          width: 3,
                                        )
                                        : null,
                                boxShadow:
                                    isPlaying
                                        ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isPlaying) ...[
                                          Icon(
                                            Icons.music_note,
                                            color: Colors.green.shade700,
                                            size: 24,
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                        Text(
                                          btn.nome,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isPlaying
                                                    ? Colors.green.shade700
                                                    : null,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPlaying)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          size: 8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditButton(),
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        tooltip: 'Adicionar novo som',
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
