import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:stock_management/Services/api_exception.dart';

/// Builds the multipart part for an image, declaring the REAL content type
/// (sniffed from the file's first bytes) instead of guessing from the file
/// name — picked files can come back with no/odd extensions, which the
/// server would then see as `application/octet-stream`.
Future<http.MultipartFile> imageMultipart(String field, File image) async {
  final raf = await image.open();
  final List<int> head;
  try {
    head = await raf.read(16);
  } finally {
    await raf.close();
  }

  final type = _sniff(head);
  if (type == null) {
    throw const ApiException(
      statusCode: 0,
      message: 'Unsupported image format. Please choose a JPG, PNG or WEBP photo.',
    );
  }
  final ext = type.subtype == 'jpeg' ? 'jpg' : type.subtype;
  return http.MultipartFile.fromBytes(
    field,
    await image.readAsBytes(),
    filename: 'upload.$ext',
    contentType: type,
  );
}

MediaType? _sniff(List<int> b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return MediaType('image', 'jpeg');
  }
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    return MediaType('image', 'png');
  }
  if (b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return MediaType('image', 'webp');
  }
  return null; // HEIC/HEIF, GIF, etc.
}
