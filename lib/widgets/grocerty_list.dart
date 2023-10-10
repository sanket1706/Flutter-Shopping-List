import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GrocetyList extends StatefulWidget {
  const GrocetyList({super.key});

  @override
  State<GrocetyList> createState() => _GrocetyListState();
}

class _GrocetyListState extends State<GrocetyList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListItems();
  }

  void _loadListItems() async {
    try {
      final url = Uri.https("fluttter-prep-13e60-default-rtdb.firebaseio.com",
          "shopping-list.json");
      final response = await http.get(url);

      if (response.body == "null") {
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItemList = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value["category"])
            .value;
        loadedItemList.add(
          GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category,
          ),
        );

        setState(() {
          _groceryItems = loadedItemList;
          _error = null;
        });
      }
    } catch (err) {
      setState(() {
        _error = "Failed to fetch data. Please try again later.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https("fluttter-prep-13e60-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget = const Center(
      child: Text("No items added yet."),
    );

    if (_groceryItems.isNotEmpty) {
      currentWidget = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) {
          return Dismissible(
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            background: Container(
              color: Colors.red,
              margin: Theme.of(context).cardTheme.margin,
            ),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          );
        },
      );
    }

    if (_error != null) {
      currentWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(
              height: 8,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadListItems();
              },
              child: const Text("Reload"),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      currentWidget = const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: currentWidget,
    );
  }
}
