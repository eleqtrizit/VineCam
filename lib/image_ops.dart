import 'package:image/image.dart';
import 'dart:io';

class ImageOps{
  int processing = 0;

  saveThumb(path) {
    processing++;
    // decodeImage will identify the format of the image and use the appropriate
    // decoder.
    File resizeThisFile = File(path);
    Image image = decodeImage(resizeThisFile.readAsBytesSync());

    // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
    Image thumbnail = copyResize(image, width: 300);

    var newPath = path.replaceAll(new RegExp(r'.jpg'), '.png');

    // Save the thumbnail as a PNG.
    new File(newPath).writeAsBytesSync(encodePng(thumbnail));
    processing--;
  }

  // deletion will come from the full size picture pane (jpg)
  void delete(path) {
    var newPath = path.replaceAll(new RegExp(r'.jpg'), '.png');
    print("Gonna delete!");
    File f = new File.fromUri(Uri.file(path));
    f.delete();
    File f2 = new File.fromUri(Uri.file(newPath));
    f2.delete();
  }

  String getFullSize(path){
    var newPath = path.replaceAll(new RegExp(r'.png'), '.jpg');
    return newPath;
  }
}