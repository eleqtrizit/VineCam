import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'grape_model.dart';

Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build (BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Multi Page Application Page-1"),
      ),
      body: new Text("Another Page...!!!!!!"),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  var _appDir = "";
  var _vineyardRow = 1;
  var _batch = 1;
  var _picCount = 0;
  var _currentDir = "";
  List<Grape> _grapes = [];
  Grape _currentGrape;
  List<String> _direction = [];
  var _currentDirection="";

  void populateDirections() {
    _direction.add("N");
    _direction.add("S");
    _direction.add("E");
    _direction.add("W");
  }

  void setCurrentDirection(){
    if (_currentDirection==""){
      print("Setting direction to " + _direction[0]);
      _currentDirection=_direction[0];
    }
  }

  void populateGrapes() {
    _grapes.add(new Grape("Cabernet Sauvignon"));
    _grapes.add(new Grape("Syrah"));
  }

  void setCurrentGrape(){
    if (_currentGrape==null){
      _currentGrape = _grapes[0];
    }
  }

  Future setAppDirectory() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    print(appDir.path);
    setState(() {
      _appDir = appDir.path;
    });
    setDirectory();
  }

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    setAppDirectory();
    populateGrapes();
    setCurrentGrape();
    populateDirections();
    setCurrentDirection();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  String getDate(){
    var date = DateTime.now();
    var retDate = date.year.toString() + '.' + date.month.toString() + '.' +date.day.toString();
    return retDate;
  }

  String getFilename(){
    var date = DateTime.now();
    var retDate = date.hour.toString() + "." + date.minute.toString() + "." +date.second.toString();
    return retDate + '.jpg';
  }

  List<FileSystemEntity> listImages(path){
    var dir = new Directory(path);
    List contents = dir.listSync();
    return contents;
  }

  String getPath(){
    var date = getDate();
    return '$_appDir/$date/vine_$_vineyardRow.toString()/batch_$_batch.toString()/';
  }

  setDirectory() async {
    final path = getPath();
    if (_currentDir != path) {
      await new Directory(path).create(recursive: true);
      setImageCount(path);
      setState(() {
        _currentDir = path;
      });
    }
  }

  changeBatch(diff){
    var newNum =_batch + diff;
    if (newNum>0){
      setState(() {
        _batch = _batch + diff;
      });
    }
  }

  changeVine(diff) {
    var newNum = _vineyardRow + diff;
    if (newNum>0){
      setState(() {
        _vineyardRow = _vineyardRow + diff;
      });
    }
  }

  Future<void> setImageCount(path) async {
    List contents = listImages(path);
    setState(() {
      _picCount = contents.length;
    });
  }

  Future<void> incImageCount() async {
    setState(() {
      _picCount++;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: new Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return CameraPreview(_controller);
              } else {
                // Otherwise, display a loading indicator.
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            top: 30,
            left: 10,
            child: Text(_currentDirection,
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 24),
            ),
          ),
          Positioned(
            top: 30,
            left: 60,
            child: Text(_currentGrape.getGrapeName(),
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 24),
            ),
          ),
          Positioned(
            top: 20,
            right: 0,
            child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(builder: (context) => new SettingsScreen()),
                  );
                },
                child: Icon(Icons.settings),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text("Vine",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 24)),
                FloatingActionButton(
                  onPressed: () {
                    changeVine(1);
                    setDirectory();
                  },
                  child: Icon(Icons.arrow_upward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                Text(_vineyardRow.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 20)),
                FloatingActionButton(
                  onPressed: () {
                    changeVine(-1);
                    setDirectory();
                  },
                  child: Icon(Icons.arrow_downward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                )
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text("Pics\n" + _picCount.toString() + "\n\n",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 24)),
                Text("Batch",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 24)),
                FloatingActionButton(
                  onPressed: () {
                    changeBatch(1);
                    setDirectory();
                  },
                  child: Icon(Icons.arrow_upward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                Text(_batch.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 20)),
                FloatingActionButton(
                  onPressed: () {
                    changeBatch(-1);
                    setDirectory();
                  },
                  child: Icon(Icons.arrow_downward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                )
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                child: Icon(Icons.camera_alt, size: 50),
                // Provide an onPressed callback.
                onPressed: () async {
                  // Take the Picture in a try / catch block. If anything goes wrong,
                  // catch the error.
                  try {
                    // Ensure that the camera is initialized.
                    await _initializeControllerFuture;

                    var filename = getFilename();
                    setDirectory();

                    // Attempt to take a picture and log where it's been saved.
                    await _controller.takePicture(_currentDir+filename);
                    await incImageCount();

                  } catch (e) {
                    // If an error occurs, log the error to the console.
                    print(e);
                  }
                }),
          ),
        ],
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
