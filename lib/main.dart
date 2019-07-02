import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

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
  var _vineyardRow = 0;
  var _batch = 0;

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
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
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
          Container(
            height: 80,
            child: AppBar(
              title: Text('Barbara - South'),
              backgroundColor: Colors.transparent,
            ),
          ),
          Positioned(
            top: 20,
            right: 0,
            child: FloatingActionButton(
                onPressed: () {},
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
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _vineyardRow++;
                    });
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
                    setState(() {
                      _vineyardRow--;
                    });
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
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _batch++;
                    });
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
                    setState(() {
                      _batch--;
                    });
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

                    // Construct the path where the image should be saved using the
                    // pattern package.
                    final path = join(
                      // Store the picture in the temp directory.
                      // Find the temp directory using the `path_provider` plugin.
                      (await getTemporaryDirectory()).path,
                      '${DateTime.now()}.png',
                    );

                    // Attempt to take a picture and log where it's been saved.
                    await _controller.takePicture(path);

                    setState(() {
                      _batch++;
                    });
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
