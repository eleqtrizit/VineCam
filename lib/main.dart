import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'grape_model.dart';
import 'file_list_model.dart';
import 'image_ops.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';


var test = "";


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
  var _appDir = "";
  var _vineyardRow = 1;
  var _cluster = 1;
  var _picCount = 0;
  var _currentDir = "";
  List<Grape> _grapes = [];
  Grape _currentGrape = Grape('loading');
  var _currentDirection = "North";
  bool photoDirectoryInitialized = false;
  var imageOps = ImageOps();

  @override
  void initState() {
    super.initState();
    populateGrapes();
    requestWritePermission();
  }

  void initStage2() {
    setAppDirectory(); // contains _read()
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    _vineyardRow = prefs.getInt('_vineyardRow') ?? 1;
    _cluster = prefs.getInt('_cluster') ?? 1;
    var grapeName = prefs.getString('_currentGrape') ?? _grapes[0].getGrapeName();
    _currentGrape = new Grape(grapeName);
    _currentDirection = prefs.getString('_currentDirection') ?? 'North';
    print('read: $_vineyardRow');
    print('read: $_cluster');
    print('read: $grapeName');
    print('read: $_currentDirection');
    setImageCount(_appDir);
    setState(() {
      print('Settings loaded');
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('_vineyardRow', _vineyardRow);
    prefs.setInt('_cluster', _cluster);
    prefs.setString('_currentGrape', _currentGrape.getGrapeName());
    prefs.setString('_currentDirection', _currentDirection);
    print('saved $_vineyardRow');
    print('saved: $_cluster');
    print('saved ${_currentGrape.getGrapeName()}');
    print('saved: $_currentDirection');
  }

  Color isActive(cmp1, cmp2) {
    if (cmp1 == cmp2) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  getEpoch(d) async {
    DateTime lastModDate = await File(d).lastModified();
    return lastModDate;
  }

  Future loadImageList(directory) async {
    List allImages = [];
    var dirList = directory.list(recursive: true, followLinks: false);
    List<PhotoFile> fullSizeList = [];
    List<PhotoFile> thumbList = [];

    await for (FileSystemEntity entity in dirList) {
      if (entity is File) {
        if (entity.path.contains('jpg')) {
          fullSizeList.add(new PhotoFile(entity.path));
        }
        else {
          thumbList.add(new PhotoFile(entity.path));
        }
      }
    }

    thumbList.sort((a,b) => a.compareTo(b));
    for (var file in thumbList){
      allImages.add(file.path);
    }

    return allImages;
  }

  Future showPicture(BuildContext context, path,dirPath) async {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context)
    {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: <Widget>[
              Image.asset(
                imageOps.getFullSize(path),
                  fit: BoxFit.contain
              ),
              FloatingActionButton(
                heroTag: "delPhoto",
                onPressed: () {
                  imageOps.delete(path);
                  //imageCache.clear();
                  setImageCount(dirPath);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  showGallery(context,dirPath);
                },
                child: Icon(Icons.delete,
                  size: 60
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ),
      );
    }));
  }




  Future showGallery(BuildContext context, dirPath) async {
    Directory directory = new Directory(dirPath);
    List allImages = await loadImageList(directory);
    return Navigator.of(context).push(MaterialPageRoute(builder: (context)
    {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('Photo Gallery'),
        ),
        body: _buildGrid(allImages.reversed.toList(),dirPath),
      );
    }));
  }

  Widget _buildGrid(allImages,dirPath) {
    return GridView.extent(
        maxCrossAxisExtent: 400.0,
        // padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        children: _buildGridTileList(allImages.length,allImages,dirPath));
  }

  List<GestureDetector> _buildGridTileList(int count,List allImages,dirPath) {
    return List<GestureDetector>.generate(
        count,
        (int index) => GestureDetector(
          onTap: (){
            showPicture(context,allImages[index].toString(),dirPath);
          },
          child: new Container(
                child: Image.file(
                  File(allImages[index].toString()),
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.low,
            ))));
  }

  void setCurrentDirection(newDirection) {
    setState(() {
      if (newDirection == "") {
        _currentDirection = "North";
      } else {
        _currentDirection = newDirection;
      }
      setImageCount(_appDir);
      _save();
    });
  }

  void populateGrapes() {
    _grapes.add(new Grape("Cabernet Sauvignon"));
    _grapes.add(new Grape("Syrah"));
  }

  setAppDirectory() async {
    Directory appDir = await getExternalStorageDirectory();
    setState(() {
      _appDir = appDir.path + "/VineCamPhotos/";
    });
    setDirectory();
    _read();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  requestWritePermission() async {
    PermissionStatus permissionWriteStatus = await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    //PermissionStatus permissionReadStatus = await SimplePermissions.requestPermission(Permission.ReadExternalStorage);
    PermissionStatus permissionCamera = await SimplePermissions.requestPermission(Permission.Camera);
    //PermissionStatus permissionAudio = await SimplePermissions.requestPermission(Permission.RecordAudio);

    if (permissionWriteStatus == PermissionStatus.authorized && permissionCamera == PermissionStatus.authorized) {
      // To display the current output from the Camera,
      // create a CameraController.
      _controller = CameraController(
        // Get a specific camera from the list of available cameras.
          widget.camera,
          // Define the resolution to use.
          ResolutionPreset.medium,
          enableAudio: false
      );

      // Next, initialize the controller. This returns a Future.
      _initializeControllerFuture = _controller.initialize();
      //setState(() {
       // _permissionsGranted = true;
      //});
      initStage2();
    }
  }



  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  String getDate() {
    var date = DateTime.now();
    var retDate = date.year.toString() +
        '.' +
        date.month.toString().padLeft(2, '0') +
        '.' +
        date.day.toString().padLeft(2, '0');
    return retDate;
  }

  String getRootFileName(){
    var date = DateTime.now();
    var simpleDate = date.year.toString() +
        '-' +
        date.month.toString().padLeft(2, '0') +
        '-' +
        date.day.toString().padLeft(2, '0');

    // week varietal vine exposure
    var name = _appDir +
        '${_currentGrape.getGrapeFilename()}_'+
        '${simpleDate}_'+
        'vine${_vineyardRow.toString()}_'+
        '${_currentDirection}_'+
        'cluster${_cluster.toString()}_';
    return name;
  }

  String getFilename() {
    var date = DateTime.now();
    var name = getRootFileName() +
        date.hour.toString() +
        "." +
        date.minute.toString().padLeft(2, '0') +
        "." +
        date.second.toString().padLeft(2, '0');
    return name + '.jpg';
  }

  List<FileSystemEntity> listImages(path) {
     List<FileSystemEntity> contents = [];
    try {
      var dir = new Directory(path);
      contents = dir.listSync();
    }
    catch(e) {
      print("Directory does not exist: "+path);
    }

    return contents;
  }

  String getPath() {
    //var date = getDate();
    return '$_appDir/';
    //${_currentGrape.getGrapeFilename()}/$date/vine_${_vineyardRow.toString()}/$_currentDirection/cluster${_cluster.toString()}/';
  }

  setDirectory() {
    final path = getPath();
    if (_currentDir != path) {
      new Directory(path).createSync(recursive: true);
      setState(() {
        _currentDir = path;
      });
    }
  }

  changeCluster(diff) {
    var newNum = _cluster + diff;
    if (newNum > 0) {
      setState(() {
        _cluster = _cluster + diff;
        _save();
        setImageCount(_appDir);
      });
    }
  }

  changeVine(diff) {
    var newNum = _vineyardRow + diff;
    if (newNum > 0) {
      setState(() {
        _vineyardRow = _vineyardRow + diff;
        _save();
        setImageCount(_appDir);
      });
    }
  }

  Future<void> setImageCount(path) async {
    List<FileSystemEntity> contents = [];
    List<FileSystemEntity> tempContents = listImages(path);
    if (tempContents.length>0){
      contents=tempContents;
    }
    int c= 0;
    var rootFileName = getRootFileName();
    for (var element in contents){
      if (element.path.contains(rootFileName)){
        c=c+1;
      }
    }
    print('Pictures counted: $_picCount');
    setState(() {
      _picCount = c;
    });
  }

  Future<void> incImageCount() async {
    setState(() {
      _picCount++;
    });
  }

  SimpleDialogOption _directionList(val) {
    return SimpleDialogOption(
        child: Text(val + "\n\n",
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontSize: 24)),
        onPressed: () {
          setCurrentDirection(val);
          Navigator.pop(context);
          setState(() {});
        });
  }

  Widget simpleListOption(msg, callback) {
    return SimpleDialogOption(
        child: Text(msg + "\n\n",
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontSize: 24)),
        onPressed: () {
          callback(context);
        });
  }

  settingsDirection(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Set Direction'),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _directionList("North"),
                _directionList("South"),
                _directionList("East"),
                _directionList("West"),
              ],
            ),
          ));
    }));
  }

  // called below in SettingsGrapeType
  Widget buildBody(BuildContext context, int index) {
    return SimpleDialogOption(
        child: Text(_grapes[index].getGrapeName(),
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontSize: 24)),
        onPressed: () {
          setState(() {
            _currentGrape = _grapes[index];
            _save();
            setImageCount(_appDir);
          });
          Navigator.pop(context);
        });
  }

  settingsGrapeType(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Select Grape Type'),
          ),
          body: Center(
            child: new ListView.builder(
              itemCount: _grapes.length,
              itemBuilder: (BuildContext context, int index) =>
                  buildBody(context, index),
            ),
          ));
    }));
  }

  settings(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                simpleListOption("Set Direction", settingsDirection),
                simpleListOption("Set Grape Type", settingsGrapeType),
              ],
            ),
          ));
    }));
  }

  buildDirListing(BuildContext context, int index, directories) {
    return SimpleDialogOption(
        child: Text(
            directories[index]
                    .path
                    .split('/')
                    .skip(5)
                    .take(1)
                    .toList()
                    .join('') +
                "-\n" +
                directories[index]
                    .path
                    .split('/')
                    .skip(6)
                    .toList()
                    .join('     '),
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontSize: 18)),
        onPressed: () {
          setState(() {});
          //showGallery(context, directories[index]);
          showGallery(context, _appDir);
        });
  }

  Future directoryListings(BuildContext context, dirName) async {
    List<Directory> directories = [];
    var dirList =
        new Directory(dirName).list(recursive: true, followLinks: false);
    await for (FileSystemEntity entity in dirList) {
      if (entity is Directory) {
        if (entity.path.split('/').length > 9) {
          directories.add(entity);
        }
      }
    }

    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Directory'),
        ),
        body: Center(
          child: new ListView.builder(
            itemCount: directories.length,
            itemBuilder: (BuildContext context, int index) =>
                buildDirListing(context, index, directories),
          ),
        ),
      );
    }));
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
            child: Text(
              _currentDirection[0],
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
            child: Text(
              _currentGrape.getGrapeName(),
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
                heroTag: "settingsBtn",
                onPressed: () {
                  settings(context);
                },
                child: Icon(Icons.settings),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white),
          ),
          Positioned(
            top: 100,
            right: 0,
            child: FloatingActionButton(
                heroTag: "galleryBtn",
                onPressed: () {
                  showGallery(context,_appDir);
                  //directoryListings(context, _appDir);
                },
                child: Icon(Icons.image),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white),
          ),
          Positioned(
            bottom: 200,
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
                  heroTag: "incVineBtn",
                  onPressed: () {
                    changeVine(1);
                    //setDirectory();
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
                  heroTag: "decVineBtn",
                  onPressed: () {
                    changeVine(-1);
                    //setDirectory();
                  },
                  child: Icon(Icons.arrow_downward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                )
              ],
            ),
          ),
          Positioned(
            bottom: 200,
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
                Text("Cluster",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 24)),
                FloatingActionButton(
                  heroTag: "IncClusterBtn",
                  onPressed: () {
                    changeCluster(1);
                    //setDirectory();
                  },
                  child: Icon(Icons.arrow_upward),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                Text(_cluster.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 20)),
                FloatingActionButton(
                  heroTag: "decClusterBtn",
                  onPressed: () {
                    changeCluster(-1);
                    //setDirectory();
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
                heroTag: "takePictureBtn",
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
                    //setDirectory();

                    // Attempt to take a picture and log where it's been saved.
                    await _controller.takePicture(filename);
                    incImageCount();
                    imageOps.saveThumb(filename);
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
