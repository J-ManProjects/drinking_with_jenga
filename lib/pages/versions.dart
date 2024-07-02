import 'package:drinking_with_jenga/services/database_helper.dart';
import 'package:drinking_with_jenga/services/themes.dart';
import 'package:flutter/material.dart';


class Versions extends StatefulWidget {
  @override
  _VersionsState createState() => _VersionsState();
}

class _VersionsState extends State<Versions> {
  late Block block;
  Map? arguments;
  late List<Map> versionsList;

  @override
  Widget build(BuildContext context) {
    if (arguments == null) {
      arguments = ModalRoute.of(context)?.settings.arguments as Map?;
      versionsList = arguments?['versionsList'];
      block = arguments?['block'];
    }

    return Theme(
      data: Themes.getTheme(),
      child: Scaffold(
        appBar: _appBar(),
        body: _mainBody(context),
      ),
    );
  }

  // The app bar.
  PreferredSizeWidget _appBar() {
    return AppBar(
      centerTitle: true,
      title: const Text('Restore version'),
    );
  }

  // The main body.
  Widget _mainBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _heading('Current version'),
        _currentVersion(),
        _heading('Previous version${versionsList.length > 2 ? 's' : ''}'),
        Divider(
            height: 2,
            thickness: 2,
            color: Themes.getTheme().colorScheme.secondary),
        _previousVersions(context),
      ],
    );
  }

  // The appropriate heading.
  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Text(
        '$text:',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Creates the ListTile used for each versions.
  Widget _listTile(Map version,
      {int index = -1, BuildContext? context, bool hasOnTap = false}) {
    return Card(
      shape: const ContinuousRectangleBorder(),
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(version['label']),
        subtitle: Text(version['instructions']),
        trailing: Text(
          'v${version['version']}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: hasOnTap
            ? () {
                onTapPopup(context, index);
              }
            : null,
      ),
    );
  }

  // Creates the ListTile of the current version.
  Widget _currentVersion() {
    return _listTile(block.versionMap());
  }

  // Creates the list of all previous versions.
  Widget _previousVersions(BuildContext context) {

    // List of ListTile widgets.
    List<Widget> list = <Widget>[];
    for (int index = versionsList.length - 1; index >= 0; index--) {
      list.add(_listTile(
        versionsList[index],
        index: index,
        context: context,
        hasOnTap: true,
      ));
    }

    // Return the widget.
    return Expanded(
      child: ListView(
        children: list,
      ),
    );
  }

  // Implements the functionality for the specified version.
  void onTapPopup(BuildContext? context, int index) {
    showDialog(
      context: context!,
      builder: (BuildContext context) {
        return Theme(
          data: Themes.getTheme(),
          child: AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            title: Text('Version ${versionsList[index]['version']} selected'),
            content: const Text(
                'Are you sure that you want to replace the current version with the selected one?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, {
                    'version': versionsList[index]['version'],
                    'index': index,
                  });
                },
              ),
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
} // End of class definition.
