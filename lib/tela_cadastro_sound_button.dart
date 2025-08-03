import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'model/sound_button_model.dart';
import 'dao/sound_button_dao.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'permission_handler.dart';

class TelaCadastroSoundButton extends StatefulWidget {
  final SoundButtonModel? button;
  final String? audioPath;
  const TelaCadastroSoundButton({Key? key, this.button, this.audioPath})
    : super(key: key);

  @override
  State<TelaCadastroSoundButton> createState() =>
      _TelaCadastroSoundButtonState();
}

class _TelaCadastroSoundButtonState extends State<TelaCadastroSoundButton> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  String? _audioPath;
  Color _buttonColor = Colors.indigo.shade100;

  // Controle de gravação
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _hasPermission = false;

  // Controle de reprodução
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.button?.nome ?? '');
    _audioPath = widget.audioPath ?? widget.button?.audioPath;
    if (widget.button?.cor != null) {
      _buttonColor = Color(int.parse(widget.button!.cor!));
    }
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _checkPermissions();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _checkPermissions() async {
    bool hasPermission = await PermissionHandler.checkAudioPermissions();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermissions() async {
    bool granted = await PermissionHandler.requestAudioPermissions(context);
    setState(() {
      _hasPermission = granted;
    });
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
  }

  Future<void> _initPlayer() async {
    await _player!.openPlayer();
    _player!.setSubscriptionDuration(Duration(milliseconds: 100));
    _player!.onProgress!.listen((e) {
      setState(() {
        _playbackPosition = e.position;
        _playbackDuration = e.duration;
      });
    });
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestPermissions();
      if (!_hasPermission) {
        await PermissionHandler.showPermissionDeniedDialog(context);
        return;
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: filePath, codec: Codec.aacMP4);
    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _audioPath = _recordedFilePath;
    });
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;

    try {
      if (_isPlaying) {
        await _player!.stopPlayer();
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      } else {
        await _player!.startPlayer(
          fromURI: _audioPath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _playbackPosition = Duration.zero;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reproduzir áudio: $e')));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPath = result.files.single.path;
      });
    }
  }

  Future<void> _pickColor() async {
    Color? picked = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Escolha uma cor'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: _buttonColor,
                onColorChanged: (color) => Navigator.of(context).pop(color),
              ),
            ),
          ),
    );
    if (picked != null) {
      setState(() {
        _buttonColor = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _audioPath == null) return;
    final btn = SoundButtonModel(
      id: widget.button?.id,
      nome: _nomeController.text,
      audioPath: _audioPath!,
      cor: _buttonColor.value.toString(),
    );
    await insertSoundButton(btn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.button == null ? 'Adicionar Audio' : 'Editar audio'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome do botão'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              SizedBox(height: 16),

              // Seção de seleção de áudio
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecionar Áudio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _audioPath == null
                                ? 'Nenhum áudio selecionado'
                                : _audioPath!.split('/').last,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.audiotrack),
                          onPressed: _pickAudio,
                          tooltip: 'Selecionar arquivo de áudio',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Seção de gravação
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Gravar Áudio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        if (!_hasPermission) ...[
                          SizedBox(width: 8),
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                        ],
                      ],
                    ),
                    SizedBox(height: 8),
                    if (!_hasPermission) ...[
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Permissão necessária para gravar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _requestPermissions,
                              child: Text(
                                'Conceder',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isRecording
                                ? 'Gravando...'
                                : _recordedFilePath != null
                                ? 'Áudio gravado pronto!'
                                : 'Grave seu próprio áudio',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          color: _isRecording ? Colors.red : Colors.indigo,
                          onPressed:
                              (_isRecording || !_hasPermission)
                                  ? (_isRecording ? _stopRecording : null)
                                  : _startRecording,
                          tooltip:
                              _isRecording
                                  ? 'Parar gravação'
                                  : 'Iniciar gravação',
                        ),
                      ],
                    ),
                    if (_recordedFilePath != null && !_isRecording) ...[
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Usar áudio gravado'),
                        onPressed: () {
                          setState(() {
                            _audioPath = _recordedFilePath;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Áudio gravado selecionado!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Seção de reprodução (só aparece se há áudio selecionado)
              if (_audioPath != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ouvir Áudio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_isPlaying) ...[
                        Text(
                          _formatDuration(_playbackPosition),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              _playbackDuration.inMilliseconds > 0
                                  ? _playbackPosition.inMilliseconds /
                                      _playbackDuration.inMilliseconds
                                  : 0,
                          backgroundColor: Colors.green.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _playAudio,
                            icon: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(_isPlaying ? 'Parar' : 'Ouvir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(120, 40),
                            ),
                          ),
                          if (_isPlaying) ...[
                            Text(
                              'Ouvindo...',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Seção de cor
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cor do Botão',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Cor selecionada:'),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _pickColor,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _buttonColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: _pickColor,
                          child: Text('Alterar cor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Botão de salvar
              ElevatedButton(
                onPressed: _audioPath != null ? _save : null,
                child: Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget de seleção de cor (BlockPicker)
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  const BlockPicker({required this.pickerColor, required this.onColorChanged});

  static const List<Color> _colors = [
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _colors.map((color) {
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color:
                        pickerColor == color
                            ? Colors.black
                            : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }).toList(),
    );
  }
}
