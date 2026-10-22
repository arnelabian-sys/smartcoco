import 'dart:typed_data';

class PickedFile {
  final String name;
  final String type; // mime
  final int size;
  final Uint8List bytes;
  PickedFile({required this.name, required this.type, required this.size, required this.bytes});
  bool get isJpegOrPng => type == 'image/jpeg' || type == 'image/png' || name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.jpeg') || name.toLowerCase().endsWith('.png');
}
