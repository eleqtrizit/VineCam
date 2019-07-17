import 'dart:io';

class PhotoFile implements Comparable<PhotoFile> {
  final String path;
  const PhotoFile(this.path);

  getFuturesDate() {
    var dated = File(path).lastModifiedSync();
    return DateTime.parse(dated.toString()).toUtc().millisecondsSinceEpoch;
  }

  @override
  int compareTo(PhotoFile other) => getFuturesDate() - other.getFuturesDate();
}

