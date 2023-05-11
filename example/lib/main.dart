import 'dart:async';
import 'dart:math';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:background_location_tracker_example/api_service.dart';
import 'package:background_location_tracker_example/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
    (data) async => Repo().update(data),
  );
}

final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
  runApp(MyApp());
}

@override
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var isTracking = false;

  Timer? _timer;
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _getTrackingStatus();
    setInterval();
    // _startLocationsUpdatesStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> track(int seconds) async {
    await BackgroundLocationTrackerManager.initialize(
      backgroundCallback,
      config: BackgroundLocationTrackerConfig(
        loggingEnabled: true,
        androidConfig: AndroidConfig(
          notificationIcon: 'explore',
          trackingInterval: Duration(seconds: seconds),
          distanceFilterMeters: null,
        ),
        iOSConfig: const IOSConfig(
          activityType: ActivityType.FITNESS,
          distanceFilterMeters: null,
          restartAfterKill: true,
        ),
      ),
    );
  }

  TextEditingController textEditingController = TextEditingController();
  TextEditingController textEditingUploadIntervalController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children: [
                    // MaterialButton(
                    //   child: const Text('Request location permission'),
                    //   onPressed: _requestLocationPermission,
                    // ),
                    // // if (Platform.isAndroid) ...[
                    // //   const Text(
                    // //       'Permission on android is only needed starting from sdk 33.'),
                    // // ],
                    // MaterialButton(
                    //   child: const Text('Request Notification permission'),
                    //   onPressed: _requestNotificationPermission,
                    // ),
                    // MaterialButton(
                    //   child: const Text('Send notification'),
                    //   onPressed: () =>
                    //       sendNotification('Hello from another world'),
                    // ),

                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: TextField(
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Tracking Interval (Seconds)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'\d'))
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: TextField(
                        controller: textEditingUploadIntervalController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Upload Interval',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'\d'))
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: MaterialButton(
                            child: const Text('Stop Tracking'),
                            onPressed: isTracking
                                ? () async {
                                    await getDatabaseEntry();
                                    // await LocationDao().clear();
                                    // await _getLocations();
                                    await BackgroundLocationTrackerManager
                                        .stopTracking();
                                    setState(() => isTracking = false);
                                  }
                                : null,
                          ),
                        ),
                        Expanded(
                          child: MaterialButton(
                            child: const Text('Start Tracking'),
                            onPressed: isTracking
                                ? null
                                : () async {
                                    if (textEditingController.text.isEmpty) {
                                      return;
                                    }else if(textEditingUploadIntervalController.text.isEmpty){
                                      return;
                                    }

                                    final i = int.tryParse(
                                            textEditingController.text) ??
                                        0;
                                    await track(i);
                                    final prefs = await this.prefs;
                                    await prefs.reload();

                                    await prefs.setString('interval', textEditingController.text);
                                    await prefs.setString('uploadInterval', textEditingUploadIntervalController.text);

                                    await getDatabaseEntry();

                                    await BackgroundLocationTrackerManager
                                        .startTracking();
                                    setState(() => isTracking = true);
                                  },
                          ),
                        ),
                      ],
                    ),
                    Text('Offline Entries : $dbCount'),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: MaterialButton(
                        child: const Text('Upload Entries'),
                        onPressed: () async {
                          final data = await dbHelper.getData();
                          await ApiService.uploadData(data);
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  int dbCount = 0;

  Future<void> setInterval() async {
    final prefs = await this.prefs;
    await prefs.reload();
    final interval = prefs.getString('interval');
    final uploadInterval = prefs.getString('uploadInterval');
    textEditingController.text = interval ?? '';
    textEditingUploadIntervalController.text = uploadInterval ?? '';
    await getDatabaseEntry();
  }

  Future<void> getDatabaseEntry() async {
    await dbHelper.init();
    dbCount = await dbHelper.getCount();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getTrackingStatus() async {
    isTracking = await BackgroundLocationTrackerManager.isTracking();
    setState(() {});
  }

  Future<void> _requestLocationPermission() async {
    final result = await Permission.locationAlways.request();
    if (result == PermissionStatus.granted) {
      print('GRANTED'); // ignore: avoid_print
    } else {
      print('NOT GRANTED'); // ignore: avoid_print
    }
  }

  Future<void> _requestNotificationPermission() async {
    final result = await Permission.notification.request();
    if (result == PermissionStatus.granted) {
      print('GRANTED'); // ignore: avoid_print
    } else {
      print('NOT GRANTED'); // ignore: avoid_print
    }
  }

  Future<void> _getLocations() async {
    final locations = await LocationDao().getLocations();
    setState(() {
      _locations = locations;
    });
  }

  void _startLocationsUpdatesStream() {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(milliseconds: 250), (timer) => _getLocations());
  }
}

class Repo {
  static Repo? _instance;

  Repo._();

  factory Repo() => _instance ??= Repo._();

  Future<void> update(BackgroundLocationUpdateData data) async {
    final text = 'Lat: ${data.lat} Lon: ${data.lon}';
    // print(text); // ignore: avoid_print
    sendNotification(text);
    await LocationDao().saveLocation(data);
  }
}

class LocationDao {
  static const _locationsKey = 'background_updated_locations';
  static const _locationSeparator = '-/-/-/';

  static LocationDao? _instance;

  LocationDao._();

  factory LocationDao() => _instance ??= LocationDao._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveLocation(BackgroundLocationUpdateData data) async {
    final s = <String, dynamic>{};
    s['latitude'] = data.lat.toString();
    s['longitude'] = data.lon.toString();
    s['time'] = DateTime.now().toIso8601String();
    s['status'] = 0;
    await dbHelper.init();
    dbHelper.insert(s);
    final prefs = await this.prefs;
    await prefs.reload();
    final uploadInterval = prefs.getString('uploadInterval')??'0';
    final i = int.tryParse(uploadInterval)??0;
    final dbCount = await dbHelper.getCount();
    if(dbCount > i) {
      final data = await dbHelper.getData();
      await ApiService.uploadData(data);
    }

  }

  String interval = '';

  Future<List<String>> getLocations() async {
    final prefs = await this.prefs;
    await prefs.reload();
    final locationsString = prefs.getString(_locationsKey);
    if (locationsString == null) return [];
    return locationsString.split(_locationSeparator);
  }

  Future<void> clear() async => (await prefs).clear();
}

void sendNotification(String text) {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('app_icon'),
    // iOS: IOSInitializationSettings(
    //   requestAlertPermission: false,
    //   requestBadgePermission: false,
    //   requestSoundPermission: false,
    // ),
  );
  FlutterLocalNotificationsPlugin().initialize(
    settings,
    // onSelectNotification: (data) async {
    //   print('ON CLICK $data'); // ignore: avoid_print
    // },
  );
  FlutterLocalNotificationsPlugin().show(
    Random().nextInt(9999),
    'Location',
    text,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_notification',
        'Test',
        priority: Priority.low,
        importance: Importance.low,
      ),
      // iOS: IOSNotificationDetails(),
    ),
  );
}
