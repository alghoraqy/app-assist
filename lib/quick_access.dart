import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_device_name/flutter_device_name.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quick_settings/quick_settings.dart';

@pragma("vm:entry-point")
Tile onTileClicked(Tile tile) {
  final oldStatus = tile.tileStatus;
  if (oldStatus == TileStatus.active) {
    tile.label = "Server OFF";
    tile.tileStatus = TileStatus.inactive;
    tile.subtitle = "App Assist";
    onInActive();
  } else {
    tile.label = "Server ON";
    tile.tileStatus = TileStatus.active;
    tile.subtitle = "App Assist";
    onActive();
  }
  return tile;
}

@pragma("vm:entry-point")
Tile onTileAdded(Tile tile) {
  tile.label = "Server ON";
  tile.tileStatus = TileStatus.active;
  tile.subtitle = "Server is running";
  return tile;
}

@pragma("vm:entry-point")
void onTileRemoved() {
  print("Tile removed");
}

HttpServer? _server;

@pragma("vm:entry-point")
void onActive() async {
  Future<String> getIPAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        if (interface.name.contains('wlan') || interface.name.contains('en')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }

      for (var interface in await NetworkInterface.list()) {
        if (interface.name.contains('rmnet') ||
            interface.name.contains('pdp_ip')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      print("Error getting IP Address: $e");
    }
    return 'No IP Found';
  }



  ////
  String _ipAddress = 'Getting IP...';
  bool _serverStarted = false;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  DeviceName plugin = DeviceName();
  bool isBackground = false;
  AndroidDeviceInfo? androidInfo;
  PackageInfo? packageInfo;
  String? deviceName;
  String? deviceId;
  String? macAddress;
  String? ipAddress;
  ipAddress = await getIPAddress();
  androidInfo = await deviceInfo.androidInfo;
  packageInfo = await PackageInfo.fromPlatform();
  deviceName = await plugin.getName();
  String? androidId = await MobileDeviceIdentifier().getDeviceId();
  if (androidId != null) {
    deviceId = base64Encode(utf8.encode(androidId));
    macAddress = androidId;
  }

  _ipAddress = '$ipAddress:40600/AppAssist/GetMachineInfo';

  if (ipAddress != 'No IP Found') {
    // if (await FlutterBackground.hasPermissions) {
    //   isBackground = await FlutterBackground.enableBackgroundExecution();
    // }
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 40600);
      await for (HttpRequest request in _server!) {
        print(
            'Request received from: ${request.connectionInfo?.remoteAddress}');
        final resonse =
            ' "{  \\"version\\": null,  \\"entity\\": {    \\"creationDateTime\\": \\"${DateTime.now().toUtc().toIso8601String()}\\",   \\"version\\": \\"${packageInfo?.version ?? '1.0.0'}\\",    \\"macAddress\\": \\"$macAddress\\",   \\"ipAddress\\": \\"$ipAddress\\", \\"machineName\\": \\"$deviceName\\",  \\"userDomainName\\": \\"NA\\",    \\"userName\\": \\"$deviceName\\",    \\"processorName\\": \\"${androidInfo!.hardware}\\",    \\"systemName\\": \\"Android  v. ${androidInfo!.version.release}\\",    \\"accountDomainSid\\": \\"$deviceId\\",    \\"deviceId\\": \\"$deviceId\\",    \\"uuid\\": \\"$deviceId\\",    \\"diskDriveSerial\\": \\"$deviceId\\",    \\"biosSerial\\": \\"$deviceId\\",    \\"motherBoardSerialNumber\\": \\"$deviceId\\",    \\"processorId\\": \\"$deviceId\\",    \\"silentPrintIsEnabled\\": false  },  \\"returnStatus\\": true,  \\"returnMessage\\": null}"';
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', '*');
        request.response.headers.add("Access-Control-Allow-Headers", "*");
        request.response.headers.add('Content-Type', 'application/json');
        request.response.write(resonse);
        await request.response.close();
      }
    } catch (e) {
      print("Error starting server: $e");
    }
  }
}

@pragma("vm:entry-point")
void onInActive() {
  _server?.close();
  _server = null;
}

Future<void> initializeBackgroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "App Assist",
    notificationText: "Background notification to keep App Assist running",
    notificationImportance: AndroidNotificationImportance.high,
    enableWifiLock: true,
  );

  await FlutterBackground.initialize(androidConfig: androidConfig);
}
