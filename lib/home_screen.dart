import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_name/flutter_device_name.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mac_address_plus/mac_address_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _ipAddress = 'Getting IP...';
  bool _serverStarted = false;
  HttpServer? _server;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  DeviceName  plugin = DeviceName();

  AndroidDeviceInfo? androidInfo;
  PackageInfo? packageInfo;
  String? deviceName;
  String? macAddress;
  String? ipAddress;
  initAndroid() async {
    androidInfo = await deviceInfo.androidInfo;
    packageInfo = await PackageInfo.fromPlatform();
    deviceName = await plugin.getName();

    final macAddressPlusPlugin = MacAddressPlus();
    macAddress = await macAddressPlusPlugin.getMacAddress();
    // macAddress = await GetMac.macAddress;
    ipAddress = await getIPAddress();
  }

  // Future<String> getIPAddress() async {
  //   try {
  //     for (var interface in await NetworkInterface.list()) {
  //       for (var addr in interface.addresses) {
  //         if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {

  //           return addr.address;
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print("Error getting IP Address: $e");
  //   }
  //   return 'No IP Found';
  // }

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

  void startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 40600);
      setState(() => _serverStarted = true);

      await for (HttpRequest request in _server!) {
        print('Request received from: ${request.connectionInfo?.remoteAddress}');
        final resonse =
            ' "{  \\"version\\": null,  \\"entity\\": {    \\"creationDateTime\\": \\"${DateTime.now().toUtc().toIso8601String()}\\",   \\"version\\": \\"${packageInfo?.version ?? '5.0.0'}\\",    \\"macAddress\\": \\"$macAddress\\",   \\"ipAddress\\": \\"$ipAddress\\", \\"machineName\\": \\"$deviceName\\",  \\"userDomainName\\": \\"NA\\",    \\"userName\\": \\"$deviceName\\",    \\"processorName\\": \\"${androidInfo!.hardware}\\",    \\"systemName\\": \\"Android  v. ${androidInfo!.version.release}\\",    \\"accountDomainSid\\": \\"${androidInfo!.id}\\",    \\"deviceId\\": \\"${androidInfo!.id}\\",    \\"uuid\\": \\"${androidInfo!.id}\\",    \\"diskDriveSerial\\": \\"${androidInfo!.id}\\",    \\"biosSerial\\": \\"${androidInfo!.id}\\",    \\"motherBoardSerialNumber\\": \\"${androidInfo!.id}\\",    \\"processorId\\": \\"${androidInfo!.id}\\",    \\"silentPrintIsEnabled\\": false  },  \\"returnStatus\\": true,  \\"returnMessage\\": null}"';
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

  void _getIPAddressAndStartServer() async {
    String ipAddress = await getIPAddress();
    setState(() {
      _ipAddress = '$ipAddress:40600/AppAssist/GetMachineInfo';
    });

    if (ipAddress != 'No IP Found') {
      startServer();
    }
  }

  @override
  void initState() {
    initAndroid();
    super.initState();
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Mobile Server')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connect to this address from PC: $_ipAddress'),
            if (_serverStarted) const Text('Server is running...'),
            if (!_serverStarted) const Text('Starting server...'),
            const SizedBox(height: 50),
            Text(macAddress ?? 'unknown'),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  if (_serverStarted) {
                    _serverStarted = false;
                    _server?.close();
                  } else {
                    _getIPAddressAndStartServer();
                  }
                });
              },
              child: Text(_serverStarted ? 'Disconnect' : 'Connect'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
}
