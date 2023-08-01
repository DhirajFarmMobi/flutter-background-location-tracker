import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:background_location_tracker_example/database_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
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

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    var deviceId = '';


    if(Platform.isAndroid) {
      const _androidIdPlugin = AndroidId();
      final androidId = await _androidIdPlugin.getId();
      deviceId = androidId.toString();
    }

    debugPrint(deviceId);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'deviceId' : deviceId
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
