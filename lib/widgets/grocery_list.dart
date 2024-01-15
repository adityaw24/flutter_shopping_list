import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  late Future<List<GroceryItem>> _items;
  String? _errorSnackbar;

  final baseUrl =
      'flutter-shopping-list-8997d-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  void initState() {
    super.initState();
    _items = _loadItem();
  }

  Future<List<GroceryItem>> _loadItem() async {
    final url = Uri.https(baseUrl, 'shopping-list.json');

    final response = await httpRequest.fetch(url);

    if (response.body == 'null') {
      return [];
    }

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data.');
    }

    final Map<String, dynamic> listData = jsonDecode(response.body);
    final List<GroceryItem> _loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((cat) => cat.value.title == item.value['category'])
          .value;
      _loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return _loadedItems;
  }

  void _addItem() async {
    final response = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    // _loadItem();

    if (response == null) {
      return;
    }

    setState(() {
      _groceryItem.add(response);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    setState(() {
      _groceryItem.remove(item);
    });

    final url = Uri.https(baseUrl, 'shopping-list/${item.id}.json');

    try {
      await httpRequest.delete(url);
    } catch (e) {
      setState(() {
        _errorSnackbar = 'Failed to delete ${item.name}';
        _groceryItem.insert(index, item);
      });
    }

    // final response = await httpRequest.delete(url);
    // if (response.statusCode >= 400) {
    //   setState(() {
    //     _isLoading = false;
    //     _errorSnackbar = 'Failed to delete ${item.name}';
    //     _groceryItem.insert(index, item);
    //   });
    //   return;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: () {
              _addItem();
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: FutureBuilder(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No data available',
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
                if (_errorSnackbar != null) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_errorSnackbar!),
                      duration: const Duration(
                        seconds: 5,
                      ),
                    ),
                  );
                }
              },
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
