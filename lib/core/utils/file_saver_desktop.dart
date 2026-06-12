import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveAndLaunchFile(Uint8List bytes, String fileName) async {
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Simpan File',
    fileName: fileName,
  );

  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsBytes(bytes);
  }
}
