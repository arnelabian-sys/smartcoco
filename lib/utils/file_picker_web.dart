import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import '../utils/picked_file.dart';

Future<PickedFile?> pickImageFile() async {
  final input = html.FileUploadInputElement()..accept = 'image/jpeg,image/png';
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  final result = reader.result;
  final Uint8List bytes;
  if (result is ByteBuffer) {
    bytes = result.asUint8List();
  } else if (result is Uint8List) {
    bytes = result;
  } else {
    bytes = Uint8List(0);
  }
  return PickedFile(name: file.name, type: file.type, size: file.size, bytes: bytes);
}
