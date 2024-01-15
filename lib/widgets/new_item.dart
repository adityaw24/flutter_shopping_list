import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/utils/http_request.dart';
import 'package:shopping_list/utils/utils.dart';

const httpRequest = HttpRequest();
const utils = Utils();
var loadConfig = utils.loadJson();

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  String _inputName = '';
  int _inputQuantity = 1;
  var _inputCategory = categories[Categories.vegetables]!;
  bool _isSending = false;
  String? _error;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      final url = Uri.https(
          'flutter-shopping-list-8997d-default-rtdb.asia-southeast1.firebasedatabase.app',
          'shopping-list.json');

      var body = jsonEncode(
        {
          'name': _inputName,
          'quantity': _inputQuantity,
          'category': _inputCategory.title,
        },
      );

      final response = await httpRequest.post(url, body);
      if (response.statusCode >= 400) {
        setState(() {
          _isSending = false;
          _error = 'Failed to submit data';
        });
        return;
      }

      final resData = jsonDecode(response.body);

      setState(() {
        _isSending = false;
      });

      if (!context.mounted) {
        return;
      }
      // Navigator.of(context).pop();

      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          name: _inputName,
          quantity: _inputQuantity,
          category: _inputCategory,
        ),
      );
    }
  }

  void _resetInput() {
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: ((value) {
                  if (value == null || value.isEmpty) {
                    return 'Required Input';
                  }
                  return null;
                }),
                onSaved: (value) {
                  _inputName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: _inputQuantity.toString(),
                      validator: ((value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value)! <= 0 ||
                            int.tryParse(value) == null) {
                          return 'Required Input';
                        }
                        return null;
                      }),
                      onSaved: (value) {
                        _inputQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _inputCategory,
                      decoration: const InputDecoration(
                        label: Text('Category'),
                      ),
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(category.value.title),
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        setState(() {
                          _inputCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _resetInput();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _saveItem();
                            if (_error != null) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_error!),
                                  duration: const Duration(
                                    seconds: 5,
                                  ),
                                ),
                              );
                            }
                          },
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add Item'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
