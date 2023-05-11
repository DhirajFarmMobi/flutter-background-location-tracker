import 'dart:convert';

import 'package:background_location_tracker_example/database_helper.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String url = 'http://192.168.1.14:4000/api/addTrack/';

  static Future<void> uploadData(List<dynamic> body) async {

    // final dbHelper = DatabaseHelper();
    // await dbHelper.init();
    //
    // for(var i = 0; i < body.length; i++){
    //   await dbHelper.updateData(body[i]);
    // }


    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      final dbHelper = DatabaseHelper();
      await dbHelper.init();

      for(var i = 0; i < body.length; i++){
        await dbHelper.updateData(body[i]);
      }

    }
  }
}
