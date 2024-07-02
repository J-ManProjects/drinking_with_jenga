// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:drinking_with_jenga/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drinking_with_jenga/services/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final searchControl = TextEditingController();
  final scrollControl = ScrollController();
  final searchFocus = FocusNode();
  late BuildContext bodyContext;
  bool hasBuilt = false;
  int buildingCount = 0;
  late List<Block> searchBlocks;
  late DatabaseHelper db;
  dynamic data;
  late String appVersion, appName;
  final Map blocksToDelete = {};
  late double height;

  // Constructs the layout of the home page.
  @override
  Widget build(BuildContext context) {
    if (!hasBuilt) {
      hasBuilt = true;
      init(context);
    }

    // debugging
    buildingCount++;
    print('(home.dart) Building ... ($buildingCount)');
    print('(home.dart) >> highestID = ${Block.getHighestID()}');

    // The main component of the widget tree.
    return AnimatedTheme(
      data: Themes.getTheme(),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: _searchBar(context),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return _mainBody(context);
          },
        ),
        drawer: _drawer(context),
        floatingActionButton: _floatingActionButton(context),
      ),
    );
  }

  // Initialises the configuration.
  void init(BuildContext context) {
    data = ModalRoute.of(context)?.settings.arguments;
    db = data['database'];
    appName = data['appName'];
    appVersion = data['appVersion'];

    // debugging
    print('(home.dart) highestID = ${Block.getHighestID()}');

    searchBlocks = [...db.allBlocks];
    scrollControl.addListener(() {
      hideKeyboard();
    });
  }

  // Saves the startup configurations to shared preferences.
  void saveConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', Themes.isDarkMode);
    prefs.setBool('showItemCount', Themes.showItemCount);

    // debugging
    print('(home.dart) Saving configuration...');
    print('(home.dart) >> darkMode = ${Themes.isDarkMode}');
    print('(home.dart) >> showItemCount = ${Themes.showItemCount}');
  }

  // Main body of the app.
  Widget _mainBody(BuildContext context) {
    bodyContext = context;
    return Column(
      children: <Widget>[
        _itemCount(),
        _mainDivider(),
        _itemList(context),
      ],
    );
  }

  // The complete layout and functionality of the search bar.
  Widget _searchBar(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextFormField(
          focusNode: searchFocus,
          controller: searchControl,
          textAlignVertical: TextAlignVertical.center,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String text) {
            setState(() {
              searchBlocks = filterStartsWith(text);
            });
          },
          decoration: InputDecoration(
            filled: true,
            border: InputBorder.none,
            hintText: 'Search',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search bar',
              onPressed: () {
                searchControl.clear();
                setState(() {
                  searchBlocks = filterStartsWith('');
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // Creates the item count text. It disappears and reappears on toggle.
  Widget _itemCount() {
    String counterText = 'Showing ${searchBlocks.length} item';
    if (searchBlocks.length != 1) {
      counterText += 's';
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: Themes.showItemCount ? 30 : 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          counterText,
        ),
      ),
    );
  }

  // Creates the divider between the item count text and the list of blocks.
  // It disappears and reappears on toggle.
  Widget _mainDivider() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: Themes.showItemCount ? 2 : 0,
      child: Divider(
        height: 2,
        thickness: 2,
        color: Themes.getTheme().colorScheme.secondary,
      ),
    );
  }

  // If the search bar shows > 0 results, creates a list of items.
  // Otherwise, indicate 'Nothing to show'.
  Widget _itemList(BuildContext context) {
    return Expanded(
      child: searchBlocks.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ListView.builder(
                controller: scrollControl,
                itemCount: searchBlocks.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shape: const ContinuousRectangleBorder(),
                    child: ListTile(
                      // debugging
                      ////////////////////////////////////////////////////////////
                      // leading: Text(
                      //   'ID=${searchBlocks[index].getID()}',
                      //   style: TextStyle(
                      //     // decoration: TextDecoration.underline,
                      //     fontWeight: FontWeight.bold,
                      //     // fontStyle: FontStyle.italic,
                      //     fontSize: 16,
                      //   ),
                      // ),
                      // trailing: Text(
                      //   'v${searchBlocks[index].getVersion()}',
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 16,
                      //   ),
                      // ),
                      ////////////////////////////////////////////////////////////

                      title: Text(searchBlocks[index].label),
                      onTap: () {
                        labelOnPress(context, index);
                      },
                      onLongPress: () {
                        labelOnLongPress(context, index);
                      },
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Text(
                'Nothing to show',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
    );
  }

  // Shows and implements the floating action button.
  Widget _floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Add new item',
      onPressed: () {
        hideKeyboard();
        add(context);
      },
      child: const Icon(Icons.add),
    );
  }

  // Drawer heading.
  Widget _drawerHeading(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          color: Themes.getHeadingColor(),
          fontSize: 14,
        ),
      ),
    );
  }

  // Shows and implements a left drawer menu.
  Widget _drawer(BuildContext context) {

    // Configures all elements in the drawer list.
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            width: 150,
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/jenga.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Divider(height: 1),
          _drawerHeading('List management'),
          _addNewTile(context),
          _defaultTile(context),
          const Divider(height: 1),
          _drawerHeading('Customisation'),
          _darkModeTile(context),
          _itemCountTile(context),
          const Divider(height: 1),
          _drawerHeading('Other'),
          _aboutTile(context),
          _exitTile(context),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // Returns the implemented "New entry" ListTile.
  Widget _addNewTile(BuildContext context) {
    return ListTile(
      title: const Text('Add new item'),
      leading: const Icon(Icons.add),
      onTap: () {
        Navigator.pop(context);
        hideKeyboard(context: context);
        add(context);
      },
    );
  }

  // Returns the implemented "Restore list to default" ListTile.
  ListTile _defaultTile(BuildContext context) {
    return ListTile(
      title: const Text('Restore list to default'),
      leading: const Icon(Icons.restore_sharp),
      onTap: () {
        Navigator.pop(context);
        hideKeyboard(context: context);
        restoreDefaultList(context);
      },
    );
  }

  // Returns the implemented "Dark mode" ListTile.
  ListTile _darkModeTile(BuildContext context) {
    return ListTile(
      title: const Text('Dark mode'),
      subtitle: Text(Themes.isDarkMode ? 'Enabled' : 'Disabled'),
      leading: const Icon(Icons.nights_stay_sharp),
      trailing: Switch(
        activeTrackColor: Themes.getNeutralColor(),
        inactiveTrackColor: Colors.grey,
        value: Themes.isDarkMode,
        onChanged: (bool value) {
          _darkModeToggle(context);
        },
      ),
      onTap: () {
        _darkModeToggle(context);
      },
    );
  }

  // Returns the implemented "Dark mode" ListTile.
  void _darkModeToggle(BuildContext context) {
    hideKeyboard(context: context);
    saveConfiguration();
    setState(() {
      Themes.toggleDarkMode();
    });
  }

  // Returns the implemented "Show items count" ListTile.
  ListTile _itemCountTile(BuildContext context) {
    return ListTile(
      title: const Text('Show item count'),
      subtitle: Text(Themes.showItemCount ? 'Enabled' : 'Disabled'),
      leading: const Icon(Icons.confirmation_number_sharp),
      trailing: Switch(
        activeTrackColor: Themes.getNeutralColor(),
        inactiveTrackColor: Colors.grey,
        value: Themes.showItemCount,
        onChanged: (bool value) {
          _itemCountToggle(context);
        },
      ),
      onTap: () {
        _itemCountToggle(context);
      },
    );
  }

  // Toggles the "Show item count" switch.
  void _itemCountToggle(BuildContext context) {
    hideKeyboard(context: context);
    saveConfiguration();
    setState(() {
      Themes.toggleItemCount();
    });
  }

  // Returns the implemented "About" ListTile.
  ListTile _aboutTile(BuildContext context) {
    return ListTile(
      title: const Text('About'),
      leading: const Icon(Icons.info_sharp),
      onTap: () {
        Navigator.pop(context);
        hideKeyboard(context: context);
        showDialog(
          context: bodyContext,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Application name:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(appName),
                  const Divider(height: 24),
                  const Text(
                    'Developer:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Jacques de Villiers Malan'),
                  const Divider(height: 24),
                  const Text(
                    'Version:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(appVersion),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Returns the implemented "Exit" ListTile.
  ListTile _exitTile(BuildContext context) {
    return ListTile(
      title: const Text('Exit'),
      leading: const Icon(Icons.power_settings_new_sharp),
      onTap: () async {
        Navigator.pop(context);
        hideKeyboard(context: context);
        await Future.delayed(const Duration(milliseconds: 250), () {
          SystemNavigator.pop();
        });
      },
    );
  }

  // Shows and implements a right drawer menu.
  Widget _endDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const <Widget>[
          Text('Item 1'),
          Text('Item 2'),
          Text('Item 3'),
        ],
      ),
    );
  }

  // Shows a generic SnackBar with the given text.
  // Background color is green if positive = true.
  void showSnackBar(String text, {bool positive = false}) {
    int seconds = 2 + 2 * text.length ~/ 40;
    if (positive) {
      ScaffoldMessenger.of(bodyContext).showSnackBar(SnackBar(
        backgroundColor: Themes.getPositiveColor(),
        content: Tooltip(
          showDuration: Duration(seconds: seconds),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ));
    } else {
      ScaffoldMessenger.of(bodyContext).showSnackBar(SnackBar(
        content: Tooltip(
          showDuration: Duration(seconds: seconds),
          child: Text(text),
        ),
      ));
    }
  }

  // Hides the current SnackBar, if it exists.
  void hideSnackBar() {

    // ignore: unnecessary_null_comparison
    if (bodyContext != null) {
      ScaffoldMessenger.of(bodyContext).hideCurrentSnackBar();
    }
  }

  // Hides the keyboard, if open.
  void hideKeyboard({BuildContext? context}) {
    // debugging
    String text = '(home.dart) Hide keyboard';

    if (context == null) {
      searchFocus.unfocus();
      text += ' ==> method 1';
    } else {
      FocusScope.of(context).requestFocus(new FocusNode());
      text += ' ==> method 2';
    }
    print(text);
  }

  // Returns the blocks with labels that starts with the given text.
  List<Block> filterStartsWith(String text) {
    List<Block> filteredList = <Block>[];
    for (int i = 0; i < db.allBlocks.length; i++) {
      if (db.allBlocks[i].label
          .toLowerCase()
          .startsWith(text.toLowerCase(), 0)) {
        filteredList.add(db.allBlocks[i]);
      }
    }
    return filteredList;
  }

  // Shows the instructions of the selected label as a dialog.
  void labelOnPress(BuildContext context, int index) {
    hideKeyboard();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            searchBlocks[index].label,
            style: const TextStyle(fontSize: 18),
          ),
          content: Text(searchBlocks[index].instructions),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Shows and implements a bottom sheet for each item in the list.
  void labelOnLongPress(BuildContext context, int index) {
    hideKeyboard();

    // Configures all elements in the long press list.
    List<Widget> list = <Widget>[

      // The top is just the label of the selected item.
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          searchBlocks[index].label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Divider(
        height: 2,
        thickness: 2,
        color: Themes.getTheme().colorScheme.secondary,
      ),

      // The list items are shown from here.
      _viewTile(context, index),
      const Divider(height: 1),
      _editTile(context, index),
      const Divider(height: 1),
      _deleteTile(context, index),
      const Divider(height: 1),
      _cancelTile(context, index),
    ];

    if (searchBlocks[index].getVersion() != 1) {
      list.insert(6, const Divider(height: 1));
      list.insert(6, _restoreTile(context, index));
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext buildContext) {
        return Wrap(
          children: list,
        );
      },
    );
  }

  // Returns the implemented "View" ListTile.
  ListTile _viewTile(BuildContext context, int index) {
    return ListTile(
      title: const Text('View'),
      leading: const Icon(Icons.remove_red_eye_sharp),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200), () {
          labelOnPress(context, index);
        });
      },
    );
  }

  // Returns the implemented "Edit" ListTile.
  ListTile _editTile(BuildContext context, int index) {
    return ListTile(
      title: const Text('Edit'),
      leading: const Icon(Icons.edit_sharp),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200), () {
          edit(context, index);
        });
      },
    );
  }

  // Returns the implemented "Restore" ListTile.
  ListTile _restoreTile(BuildContext context, int index) {
    return ListTile(
      title: const Text('Restore'),
      leading: const Icon(Icons.restore_sharp),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200), () {
          restore(context, index);
        });
      },
    );
  }

  // Returns the implemented "Delete" ListTile.
  ListTile _deleteTile(BuildContext context, int index) {
    return ListTile(
      title: const Text('Delete'),
      leading: const Icon(Icons.delete_sharp),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200), () {
          delete(context, index);
        });
      },
    );
  }

  // Returns the implemented "Cancel" ListTile.
  ListTile _cancelTile(BuildContext context, int index) {
    return ListTile(
      title: const Text('Cancel'),
      leading: const Icon(Icons.cancel_sharp),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  // Restores the block list to the default list, if prompt is accepted.
  void restoreDefaultList(BuildContext context) {
    showDialog(
      context: bodyContext,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: const Text(
              'Are you sure that you want to replace the current list with the default one?'),
          actions: <Widget>[

            // Yes button, accepting a restore to the default list.
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.pop(context);
                showLoadingScreen();
                blocksToDelete.clear();
                await db.resetDatabase();
                await db.loadAllBlocks();
                searchControl.clear();
                if (searchBlocks.isNotEmpty) {
                  scrollControl.jumpTo(0);
                }
                setState(() {
                  searchBlocks = filterStartsWith(searchControl.text);
                });
                Navigator.pop(bodyContext);
                hideSnackBar();
                showSnackBar('List has been restored to default');
              },
            ),

            // No button, rejecting a restore to the default list.
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Loading indicator that also prevents touch.
  void showLoadingScreen() {
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        barrierDismissible: false,
        context: bodyContext,
        builder: (BuildContext context) {
          return const Material(
            type: MaterialType.transparency,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    });
  }

  // Inserts the given block into the list at the correct position.
  Future<void> insert(Block block) async {
    await db.insertBlock(block);
    int index = 0;
    while (index < db.allBlocks.length &&
        block.label.compareTo(db.allBlocks[index].label) > 0) {
      index++;
    }
    db.allBlocks.insert(index, block);
  }

  // Goes to the page to add a new item.
  void add(BuildContext context) async {
    hideSnackBar();

    // Wait for the new data from the edit page.
    data = await Navigator.pushNamed(context, '/add_and_edit', arguments: {
      'title': 'Add new item',
      'index': -1,
    });

    // If new data has been provided, create a new block and insert accordingly.
    if (data != null) {
      Block block = Block(
        label: data['label'],
        instructions: data['instructions'],
      );
      await insert(block);
      await db.loadBlock(block);
      await db.recreateVersionsTable(block);
      setState(() {
        searchBlocks = filterStartsWith(searchControl.text);
      });
      showSnackBar('"${data['label']}" added', positive: true);
    }
  }

  // Goes to the edit page for the selected item.
  void edit(BuildContext context, int index) async {
    hideSnackBar();

    // Wait for the new data from the edit page.
    data = await Navigator.pushNamed(context, '/add_and_edit', arguments: {
      'title': 'Edit item',
      'index': index,
      'label': searchBlocks[index].label,
      'instructions': searchBlocks[index].instructions,
    });

    // If data has been changed, update accordingly.
    if (data != null) {
      bool labelChanged = searchBlocks[index].label != data['label'];
      bool instructionsChanged =
          searchBlocks[index].instructions != data['instructions'];
      if (labelChanged || instructionsChanged) {
        // Shows the appropriate SnackBar.
        String text;
        if (labelChanged) {
          text = '"${searchBlocks[index].label}" changed to "${data['label']}"';
          if (instructionsChanged) {
            text += '\nThe instructions have also been changed';
          }
        } else {
          text =
              'The instructions of "${searchBlocks[index].label}" have been changed';
        }

        // Update in searchBlocks, allBlocks, and in the database.
        await db.insertVersion(searchBlocks[index]);
        searchBlocks[index].label = data['label'];
        searchBlocks[index].instructions = data['instructions'];
        searchBlocks[index].updateVersion();
        await db.updateBlock(searchBlocks[index]);
        setState(() {
          searchBlocks = filterStartsWith(searchControl.text);
        });
        showSnackBar(text);
      }
    }
  }

  // Goes to the versions page for the selected item.
  void restore(BuildContext context, int index) async {
    hideSnackBar();

    // Wait for the new data from the edit page.
    data = await Navigator.pushNamed(context, '/loading', arguments: {
      'block': searchBlocks[index],
    });

    // debugging
    print('(home.dart) Restore: data = $data');

    if (data != null) {
      await db.updateBlock(searchBlocks[index]);
      setState(() {
        searchBlocks = filterStartsWith(searchControl.text);
      });
      showSnackBar('Version ${data['version']} restored');
    }
  }

  // Returns a 1-to-2 line versions of the given text.
  String setMultiline(String text) {
    if (text.length > 27) {
      int index = min(text.length - 1, 27);
      while (index > 1 && text[index] != ' ') {
        index--;
      }
      return '${text.substring(0, index)}\n${text.substring(index + 1, text.length)}';
    } else {
      return text;
    }
  }

  // debugging
  ////////////////////////////////////////////////////////////
  void countdown({required int seconds}) {
    print('(home.dart) countdown: $seconds');
    if (seconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        countdown(seconds: seconds - 1);
      });
    } else {
      print('(home.dart) Finished!');
    }
  }
  ////////////////////////////////////////////////////////////

  // Deletes the item at the given index from the list.
  void delete(BuildContext context, int index) {
    hideSnackBar();

    bodyContext = context;
    late Block deletedItem;
    late int deleteIndex;

    // Remove and store the item and its index in the appropriate variables.
    setState(() {
      deletedItem = searchBlocks.removeAt(index);
    });
    deleteIndex = db.allBlocks.indexOf(deletedItem);
    db.allBlocks.removeAt(deleteIndex);
    db.deleteBlock(deletedItem);
    String text = setMultiline(deletedItem.label);

    // The unique hash code for the block ID and timestamp of this item.
    String deletedHashCode = 'id_${deletedItem.getID()}_${DateTime.now()}';
    deletedHashCode = deletedHashCode.hashCode.toString();
    blocksToDelete[deletedHashCode] = deletedItem;

    // debugging
    print('(home.dart) deletedHashCode = $deletedHashCode');
    print('(home.dart) text = $text');
    countdown(seconds: 6);

    // Wait 6 seconds and then delete versions database if item not restored.
    Future.delayed(const Duration(seconds: 6), () {
      if (blocksToDelete.containsKey(deletedHashCode)) {
        db.deleteVersionsDatabase(deletedItem);
        blocksToDelete.remove(deletedHashCode);

        // debugging
        print('(home.dart) Deleted versions block: $deletedItem}');
      }
    });

    // SnackBar showing deleted item with undo option.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      padding: const EdgeInsets.only(left: 14),
      duration: const Duration(seconds: 4, milliseconds: 800),
      backgroundColor: Themes.getNegativeColor(),
      content: Row(
        children: <Widget>[
          CircularCountDownTimer(
            isReverseAnimation: true,
            isTimerTextShown: false,
            width: 20,
            height: 20,
            duration: 5,
            fillColor: Colors.white,
            ringColor: Themes.getNegativeColor(),
          ),
          const SizedBox(width: 14),
          Text(
            '"$text" deleted',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () {
          blocksToDelete.remove(deletedHashCode);
          db.allBlocks.insert(deleteIndex, deletedItem);
          db.insertBlock(deletedItem);
          setState(() {
            searchBlocks = filterStartsWith(searchControl.text);
          });
          hideSnackBar();
          showSnackBar('"${deletedItem.label}" restored', positive: true);
        },
      ),
    ));
  }
} // End of class definition.