import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dao/sound_button_dao.dart';
import 'model/sound_button_model.dart';
import 'tela_cadastro_sound_button.dart';
import 'permission_handler.dart';

class TelaGravacaoAudio extends StatefulWidget {
  const TelaGravacaoAudio({super.key});

  @override
  State<TelaGravacaoAudio> createState() => _TelaGravacaoAudioState();
}

class _TelaGravacaoAudioState extends State<TelaGravacaoAudio> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  String? _recordedFileName;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
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
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> _initPlayer() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();

    _player!.setSubscriptionDuration(Duration(milliseconds: 100));
    _player!.onProgress!.listen((e) {
      setState(() {
        _playbackPosition = e.position;
        _playbackDuration = e.duration;
      });
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestPermissions();
      if (!_hasPermission) {
        await PermissionHandler.showPermissionDeniedDialog(context);
        return;
      }
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFileName = 'gravacao_$timestamp.aac';
      _recordedFilePath = '${directory.path}/$_recordedFileName';

      await _recorder!.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recorder!.onProgress!.listen((e) {
        setState(() {
          _recordingDuration = e.duration;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao iniciar gravação: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gravação finalizada!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao parar gravação: $e')));
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) return;

    try {
      await _player!.startPlayer(
        fromURI: _recordedFilePath,
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reproduzir: $e')));
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _player!.stopPlayer();
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao parar reprodução: $e')));
    }
  }

  Future<void> _saveRecording() async {
    if (_recordedFilePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nenhuma gravação para salvar')));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TelaCadastroSoundButton(audioPath: _recordedFilePath),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Áudio salvo com sucesso!')));
      setState(() {
        _recordedFilePath = null;
        _recordedFileName = null;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gravação de Áudio'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Como usar'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. Toque em "Gravar" para iniciar a gravação'),
                          SizedBox(height: 8),
                          Text('2. Toque em "Parar" para finalizar'),
                          SizedBox(height: 8),
                          Text('3. Use "Ouvir" para escutar a gravação'),
                          SizedBox(height: 8),
                          Text('4. "Salvar" adiciona ao SoundPad'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Entendi'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_hasPermission)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Permissão Necessária',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Este app precisa de permissão para gravar áudio',
                      style: TextStyle(color: Colors.orange.shade700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _requestPermissions,
                      child: Text('Conceder Permissão'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    _isRecording ? Colors.red.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_off,
                    size: 50,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _isRecording ? 'Gravando...' : 'Pronto para gravar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red : Colors.grey,
                    ),
                  ),
                  if (_isRecording) ...[
                    SizedBox(height: 10),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      (_isRecording || !_hasPermission)
                          ? null
                          : _startRecording,
                  icon: Icon(Icons.fiber_manual_record),
                  label: Text('Gravar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: Icon(Icons.stop),
                  label: Text('Parar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            if (_recordedFilePath != null) ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.audiotrack,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Gravação Concluída',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    if (_isPlaying) ...[
                      Text(
                        _formatDuration(_playbackPosition),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value:
                            _playbackDuration.inMilliseconds > 0
                                ? _playbackPosition.inMilliseconds /
                                    _playbackDuration.inMilliseconds
                                : 0,
                        backgroundColor: Colors.blue.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      SizedBox(height: 10),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isPlaying ? _stopPlayback : _playRecording,
                          icon: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(_isPlaying ? 'Parar' : 'Ouvir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: Size(120, 45),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _saveRecording,
                          icon: Icon(Icons.save),
                          label: Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(120, 45),
                          ),
                        ),
                      ],
                    ),
                    if (_isPlaying) ...[
                      SizedBox(height: 10),
                      Text(
                        'Ouvindo gravação...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
