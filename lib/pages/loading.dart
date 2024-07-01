import 'package:drinking_with_jenga/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drinking_with_jenga/services/themes.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/material.dart';


// This page loads the saved preferences and the database values.
class Loading extends StatefulWidget {
  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  DatabaseHelper database;
  List<Map> versionsList;
  int loadingCount = 0;
  bool hasBuilt = false;
  String text;
  Map arguments;


  @override
  Widget build(BuildContext context) {

    // Only runs first time.
    if (!hasBuilt) {
      hasBuilt = true;
      init(context);
    }

    // debugging
    loadingCount++;
    print('(loading.dart) Loading ... ($loadingCount)');

    return Theme(
      data: Themes.getTheme(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SpinKitWanderingCubes(
                color: Themes.getTheme().accentColor,
                size: 50,
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Loads the initial configuration.
  void init(BuildContext context) {

    // Loads data if currently data.
    arguments = ModalRoute.of(context).settings.arguments;

    // debugging
    print('(loading.dart) Loading:');
    print('(loading.dart) >> arguments = $arguments');

    // if no data is provided, it starts up. Otherwise, load the versions.
    if (arguments == null) {

      // debugging
      print('(loading.dart) ========================================');
      print('(loading.dart) STARTUP');
      print('(loading.dart) ========================================');

      text = 'Loading startup data';
      loadConfiguration();
      loadStartupData(context);
    } else {

      // debugging
      print('(loading.dart) ========================================');
      print('(loading.dart) VERSIONS');
      print('(loading.dart) ========================================');

      text = 'Loading versions';
      loadVersionsData(context);
    }
  }


  // Load the startup configurations saved within shared preferences.
  void loadConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // debugging
    print('(loading.dart) Loading configuration...');

    if (prefs.containsKey('darkMode')) {
      Themes.isDarkMode = prefs.getBool('darkMode');
      print('(loading.dart) >> darkMode = ${Themes.isDarkMode}');
    }

    if (prefs.containsKey('showItemCount')) {
      Themes.showItemCount = prefs.getBool('showItemCount');
      print('(loading.dart) >> showItemCount = ${Themes.showItemCount}');
    }

    setState(() {});
  }


  // Load the startup data from the database.
  void loadStartupData(BuildContext context) async {
    database = DatabaseHelper();
    await database.loadAllBlocks();
    await database.createAllVersionsTables();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Navigator.pushReplacementNamed(context, '/home', arguments: {
      'database': database,
      'appName': packageInfo.appName,
      'appVersion': packageInfo.version,
    });
  }


  // Load the versions data from the database.
  void loadVersionsData(BuildContext context) async {
    Block block = arguments['block'];
    versionsList = await DatabaseHelper.getVersionsList(block);

    // debugging
    for (int i = 0; i < versionsList.length; i++) {
      print('(loading.dart) versionsList[$i] = ${versionsList[i]}');
    }

    dynamic data = await Navigator.pushNamed(context, '/versions', arguments: {
      'versionsList': versionsList,
      'block': block,
    });

    if (data == null) {
      Navigator.pop(context);
    } else {

      // debugging
      print('(loading.dart) data[\'version\'] = ${data['version']}');
      print('(loading.dart) versionsList[data[\'index\']] = ${versionsList[data['index']]}');

      await DatabaseHelper.deleteVersions(block, data['version']);
      DatabaseHelper.setVersion(block, versionsList[data['index']]);
      Navigator.pop(context, data);
    }
  }


} // End of class definition.
