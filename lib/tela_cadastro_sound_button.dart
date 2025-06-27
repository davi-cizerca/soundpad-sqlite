import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'model/sound_button_model.dart';
import 'dao/sound_button_dao.dart';

class TelaCadastroSoundButton extends StatefulWidget {
  final SoundButtonModel? button;
  const TelaCadastroSoundButton({Key? key, this.button}) : super(key: key);

  @override
  State<TelaCadastroSoundButton> createState() =>
      _TelaCadastroSoundButtonState();
}

class _TelaCadastroSoundButtonState extends State<TelaCadastroSoundButton> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  String? _audioPath;
  Color _buttonColor = Colors.indigo.shade100;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.button?.nome ?? '');
    _audioPath = widget.button?.audioPath;
    if (widget.button?.cor != null) {
      _buttonColor = Color(int.parse(widget.button!.cor!));
    }
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
        title: Text(widget.button == null ? 'Novo Botão' : 'Editar Botão'),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _audioPath == null
                          ? 'Nenhum áudio selecionado'
                          : _audioPath!,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.audiotrack),
                    onPressed: _pickAudio,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Cor do botão:'),
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
                ],
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _save,
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
