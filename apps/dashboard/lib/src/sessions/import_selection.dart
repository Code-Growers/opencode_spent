import 'dart:typed_data';

class ImportSelection {
  final String? jsonContent;
  final String? sqlitePath;
  final Uint8List? sqliteBytes;
  final String? sourceLabel;

  const ImportSelection.json(String this.jsonContent, {this.sourceLabel})
    : sqlitePath = null,
      sqliteBytes = null;

  const ImportSelection.sqlitePath(String this.sqlitePath, {this.sourceLabel})
    : jsonContent = null,
      sqliteBytes = null;

  const ImportSelection.sqliteBytes(
    Uint8List this.sqliteBytes, {
    this.sourceLabel,
  }) : jsonContent = null,
       sqlitePath = null;
}
