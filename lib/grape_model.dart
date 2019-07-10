class Grape {
  var  _name="";
  var  _filename="";

  Grape(name) {
    addGrape(name);
  }

  addGrape(name){
    _name=name;
    _filename=name.replaceAll(new RegExp(r"\s+"), "_");
  }

  getGrapeName(){
    return _name;
  }

  getGrapeFilename(){
    return _filename;
  }
}