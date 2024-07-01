import 'package:drinking_with_jenga/services/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// This page allows for adding and editing the parameters of the blocks.
class AddAndEdit extends StatefulWidget {
  @override
  _AddAndEditState createState() => _AddAndEditState();
}

class _AddAndEditState extends State<AddAndEdit> {
  final labelControl = TextEditingController();
  final instructionsControl = TextEditingController();
  bool enabled = true;
  String title;
  Map data;

  
  @override
  Widget build(BuildContext context) {

    // Get the block data.
    if (data == null) {
      data = ModalRoute.of(context).settings.arguments;

      // If not a new block, get the label and instructions.
      if (data['index'] != -1) {
        labelControl.text = data['label'];
        instructionsControl.text = data['instructions'];
      }
    }

    // Main widget tree.
    return Theme(
      data: Themes.getTheme(),
      child: Scaffold(
        appBar: _appBar(),
        body: _mainBody(context),
      ),
    );
  }


  // The app bar.
  Widget _appBar() {
    return AppBar(
      centerTitle: true,
      title: Text(data['title']),
    );
  }


  // The main body.
  Widget _mainBody(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _heading('Label'),
            _textFormField(labelControl, 'label'),
            _heading('Instructions'),
            _textFormField(instructionsControl, 'instructions'),
            _buttonBar(context),
          ],
        ),
      ),
    );
  }


  // The appropriate heading.
  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 0, 4),
      child: Text(
        '$text:',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  // The text form field for either the label or the instructions.
  Widget _textFormField(TextEditingController controller, String section) {
    return TextFormField(
      controller: controller,
      maxLines: section == 'label' ? 1 : 5,
      minLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (String text) => setState(() {}),
      decoration: InputDecoration(
        filled: true,
        prefixIcon: data['index'] == -1 ? null : IconButton(
          icon: Icon(Icons.restore),
          tooltip: 'Reset $section text',
          onPressed: () {
            setState(() {
              controller.text = data[section];
              Future.delayed(Duration(milliseconds: 100), () {
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              });
            });
          },
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          tooltip: 'Clear $section text',
          onPressed: () {
            setState(() {
              controller.clear();
            });
          },
        ),
        hintText: 'New $section',
        border: InputBorder.none,
      ),
    );
  }


  // The button bar with Accept, Reset all (if applicable), and Cancel.
  ButtonBar _buttonBar(BuildContext context) {
    List<Widget> buttons = <Widget>[
      _accept(context),
      _cancel(context),
    ];

    if (data['index'] != -1) {
      buttons.insert(1, _resetAll(context));
    }

    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: buttons,
    );
  }


  // The accept button.
  Widget _accept(BuildContext context) {
    return RaisedButton.icon(
      label: Text('Accept'),
      icon: Icon(Icons.check),
      color: Themes.getPositiveColor(),
      onPressed: labelControl.text.isEmpty ||
          instructionsControl.text.isEmpty ? null : () {
        Navigator.pop(context, {
          'index': data['index'],
          'label': labelControl.text,
          'instructions': instructionsControl.text,
        });
      },
    );
  }


  // The reset all button for editing a block.
  Widget _resetAll(BuildContext context) {
    return RaisedButton.icon(
      label: Text('Reset all'),
      icon: Icon(Icons.restore),
      color: Themes.getNeutralColor(),
      onPressed: () {
        FocusScope.of(context).unfocus();
        setState(() {
          labelControl.text = data['label'];
          instructionsControl.text = data['instructions'];
        });
      },
    );
  }


  // The cancel button.
  Widget _cancel(BuildContext context) {
    return RaisedButton.icon(
      label: Text('Cancel'),
      icon: Icon(Icons.cancel),
      color: Themes.getNegativeColor(),
      onPressed: () {
        Navigator.pop(context, null);
      },
    );
  }


} // End of class definition.