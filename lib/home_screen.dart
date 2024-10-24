import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_name/flutter_device_name.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile_device_identifier/mobile_device_identifier.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DeviceName plugin = DeviceName();

  AndroidDeviceInfo? androidInfo;
  PackageInfo? packageInfo;
  String? deviceName;
  String? deviceId;
  String? macAddress;
  String? ipAddress;
  initAndroid() async {
    androidInfo = await deviceInfo.androidInfo;
    packageInfo = await PackageInfo.fromPlatform();
    deviceName = await plugin.getName();
    String? androidId = await MobileDeviceIdentifier().getDeviceId();
    if (androidId != null) {
      deviceId = base64Encode(utf8.encode(androidId));
      macAddress = androidId;
    }

    ipAddress = await getIPAddress();
  }

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
    print(deviceName);
    print(deviceId);
    print(androidInfo!.id);
    print(androidInfo!.device);
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 40600);
      setState(() => _serverStarted = true);

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
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connect to this address from PC:'),
            SizedBox(
              height: 15,
            ),
            if (_serverStarted)
              InkWell(
                onTap: () async {
                  final url = 'http://$_ipAddress';
                  if (!await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  )) {
                    throw Exception('Could not launch $url');
                  }
                },
                child: Text(
                  _ipAddress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline),
                ),
              ),
            if (_serverStarted)
              SizedBox(
                height: 15,
              ),
            if (_serverStarted)
              const Text(
                'Server is running now ... \n Click on url to open in browser',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
            if (!_serverStarted) const Text('Press connect to start server!!'),
            SizedBox(
              height: 100,
            ),
            Center(
              child: MaterialButton(
                minWidth: 250,
                color: _serverStarted ? Colors.red : Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
                child: Text(
                  _serverStarted ? 'Disconnect' : 'Connect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
