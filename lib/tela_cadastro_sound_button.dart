import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'model/sound_button_model.dart';
import 'dao/sound_button_dao.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
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
  late TextEditingController _categoriaController;
  String? _audioPath;
  Color _buttonColor = Colors.indigo.shade100;
  List<String> _existingCategories = [];
  bool _showCategoryDropdown = false;

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
    _categoriaController = TextEditingController(
      text: widget.button?.categoria ?? '',
    );
    _audioPath = widget.audioPath ?? widget.button?.audioPath;
    if (widget.button?.cor != null) {
      _buttonColor = Color(int.parse(widget.button!.cor!));
    }
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _checkPermissions();
    _initRecorder();
    _initPlayer();
    _loadExistingCategories();
  }

  Future<void> _loadExistingCategories() async {
    final categories = await findAllCategories();
    setState(() {
      _existingCategories = categories;
    });
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
    _nomeController.dispose();
    _categoriaController.dispose();
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
      categoria:
          _categoriaController.text.isNotEmpty
              ? _categoriaController.text
              : null,
    );
    await insertSoundButton(btn);
    Navigator.pop(context);
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required Color lightColor,
    required Color darkColor,
    required Color lightBorderColor,
    required Color darkBorderColor,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkColor : lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? darkBorderColor : lightBorderColor,
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 20,
                ),
                SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _categoriaController,
                decoration: InputDecoration(
                  labelText: 'Categoria (opcional)',
                  hintText: 'Ex: Música, Efeitos, Voz',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      setState(() {
                        _showCategoryDropdown = !_showCategoryDropdown;
                      });
                    },
                  ),
                ),
                onTap: () {
                  if (_existingCategories.isNotEmpty) {
                    setState(() {
                      _showCategoryDropdown = !_showCategoryDropdown;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_showCategoryDropdown && _existingCategories.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _existingCategories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    _existingCategories[index],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    _categoriaController.text = _existingCategories[index];
                    setState(() {
                      _showCategoryDropdown = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.button == null ? 'Adicionar Audio' : 'Editar audio'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCard(
                  title: 'Informações Básicas',
                  lightColor: Colors.blue.shade50,
                  darkColor: Color(0xFF1A237E).withOpacity(0.1),
                  lightBorderColor: Colors.blue.shade200,
                  darkBorderColor: Colors.blue.shade700,
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: 'Nome do botão',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                      ),
                      SizedBox(height: 16),
                      _buildCategoryField(),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildCard(
                  title: 'Selecionar Áudio',
                  lightColor: Colors.blue.shade50,
                  darkColor: Color(0xFF1A237E).withOpacity(0.1),
                  lightBorderColor: Colors.blue.shade200,
                  darkBorderColor: Colors.blue.shade700,
                  icon: Icons.audiotrack,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _audioPath == null
                              ? 'Nenhum áudio selecionado'
                              : _audioPath!.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
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
                ),
                SizedBox(height: 16),
                _buildCard(
                  title: 'Gravar Áudio',
                  lightColor: Colors.red.shade50,
                  darkColor: Color(0xFFB71C1C).withOpacity(0.1),
                  lightBorderColor: Colors.red.shade200,
                  darkBorderColor: Colors.red.shade700,
                  icon: Icons.mic,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasPermission) ...[
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.orange.shade900.withOpacity(0.3)
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.orange.shade700
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: isDark 
                                    ? Colors.orange.shade300
                                    : Colors.orange.shade700,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Permissão necessária para gravar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _requestPermissions,
                                child: Text(
                                  'Conceder',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade700,
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
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            color: _isRecording ? Colors.red : Colors.indigo,
                            onPressed: (_isRecording || !_hasPermission)
                                ? (_isRecording ? _stopRecording : null)
                                : _startRecording,
                            tooltip: _isRecording
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
                if (_audioPath != null) ...[
                  _buildCard(
                    title: 'Ouvir Áudio',
                    lightColor: Colors.green.shade50,
                    darkColor: Color(0xFF1B5E20).withOpacity(0.1),
                    lightBorderColor: Colors.green.shade200,
                    darkBorderColor: Colors.green.shade700,
                    icon: Icons.play_circle_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            value: _playbackDuration.inMilliseconds > 0
                                ? _playbackPosition.inMilliseconds /
                                    _playbackDuration.inMilliseconds
                                : 0,
                            backgroundColor: isDark 
                                ? Colors.green.shade900
                                : Colors.green.shade200,
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
                                  color: isDark 
                                      ? Colors.green.shade300
                                      : Colors.green.shade700,
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
                _buildCard(
                  title: 'Cor do Botão',
                  lightColor: Colors.orange.shade50,
                  darkColor: Color(0xFFE65100).withOpacity(0.1),
                  lightBorderColor: Colors.orange.shade200,
                  darkBorderColor: Colors.orange.shade700,
                  icon: Icons.palette,
                  child: Row(
                    children: [
                      Text(
                        'Cor selecionada:',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pickColor,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _buttonColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
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
                ),
                SizedBox(height: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            ? (isDark ? Colors.white : Colors.black)
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
