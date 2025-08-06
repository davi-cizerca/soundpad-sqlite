import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestAudioPermissions(BuildContext context) async {
    PermissionStatus audioStatus = await Permission.microphone.request();

    if (audioStatus.isDenied) {
      bool shouldShowRationale =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Permissão Necessária'),
                  content: Text(
                    'Este aplicativo precisa de permissão para gravar áudio para funcionar corretamente. '
                    'Por favor, conceda a permissão nas configurações.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Configurações'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (shouldShowRationale) {
        await openAppSettings();
      }
      return false;
    }

    if (audioStatus.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Permissão Negada'),
              content: Text(
                'A permissão de gravação de áudio foi negada permanentemente. '
                'Você precisa habilitar manualmente nas configurações do aplicativo.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: Text('Configurações'),
                ),
              ],
            ),
      );
      return false;
    }

    return audioStatus.isGranted;
  }

  static Future<bool> checkAudioPermissions() async {
    PermissionStatus audioStatus = await Permission.microphone.status;
    return audioStatus.isGranted;
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Permissão Negada'),
            content: Text(
              'Sem permissão de gravação de áudio, você não pode usar a funcionalidade de gravação. '
              'Por favor, conceda a permissão nas configurações.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Text('Configurações'),
              ),
            ],
          ),
    );
  }
}
