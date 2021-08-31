typedef SceneOrder = List<String?>;

const SceneOrder _emptyList = [];

class AssignmentSettings {
  SceneOrder buttons;
  int nBoxes;

  AssignmentSettings({this.buttons = _emptyList, this.nBoxes = 0});
}
