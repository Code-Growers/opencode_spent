import 'dart:io';

class ImportSelection {
  final String? jsonContent;
  final File? sqliteFile;
  final String? sourceLabel;

  const ImportSelection.json(String this.jsonContent, {this.sourceLabel})
    : sqliteFile = null;
  const ImportSelection.sqlite(File this.sqliteFile, {this.sourceLabel})
    : jsonContent = null;
}
