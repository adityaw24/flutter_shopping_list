import 'dart:convert';

import 'package:flutter/services.dart';

class Utils {
  const Utils();

  Future<Map<String, dynamic>> loadJson() async {
    final String jsonString = await rootBundle.loadString('config.json');
    final data = await jsonDecode(jsonString);

    return data;
  }
}
