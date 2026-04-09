import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(const FlutterHeartApp());

class FlutterHeartApp extends StatelessWidget {
  const FlutterHeartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: const HeartRateScreen(),
    );
  }
}

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  int heartRate = 0;
  String status = "اضغطي للبحث عن ساعتك";
  bool isConnecting = false;

  StreamSubscription? scanSub;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  Future<void> _askPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  void startListening() async {
    setState(() {
      isConnecting = true;
      status = "جاري البحث عن الساعة...";
    });

    scanSub?.cancel();

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final name = r.device.name.trim();
        final localName = r.advertisementData.localName.trim();
        if (name.contains("K8") || localName.contains("K8")) {
          await FlutterBluePlus.stopScan();
          scanSub?.cancel();
          _connectToClock(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
  }

  Future<void> _connectToClock(BluetoothDevice device) async {
    try {
      connectedDevice = device;
      await device.connect(timeout: const Duration(seconds: 20));
      if (mounted) setState(() => status = "جاري قياس النبض... ⏳");

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          if (mounted) {
            setState(() {
              status = "تم فصل الاتصال";
              heartRate = 0;
              isConnecting = false;
            });
          }
        }
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;

      // ✅ اسمع على كل notify characteristic في كل الـ services
      for (var service in services) {
        for (var char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          // احفظ ff02 للـ write
          if (uuid.contains("ff02")) {
            writeChar = char;
          }

          // اسمع على كل characteristic عنده notify
          if (char.properties.notify) {
            try {
              await char.setNotifyValue(true);
              print("✅ اشتركنا في: $uuid");

              char.lastValueStream.listen((value) {
                if (value.isEmpty) return;
                print("📊 [$uuid] DATA: $value");

                // ✅ النبض الحقيقي بيكون بين 50 و 150
                for (int i = 0; i < value.length; i++) {
                  if (value[i] >= 50 && value[i] <= 150) {
                    print("💓 نبض محتمل index $i: ${value[i]}");
                    if (mounted) {
                      setState(() {
                        heartRate = value[i];
                        status = "متصل بالساعة ❤️";
                      });
                    }
                    return;
                  }
                }
              });
            } catch (e) {
              print("❌ notify error on $uuid: $e");
            }
          }
        }
      }

      // ✅ ابعت command على ff02
      if (writeChar != null) {
        await writeChar.write([0x15, 0x01, 0x01], withoutResponse: true);
        print("✅ command أُرسل");
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          status = "فشل الاتصال: $e";
          isConnecting = false;
        });
      }
    }
  }

  String getMessage() {
    if (heartRate == 0) return "مستعدين نبدأ؟";
    if (heartRate > 100) return "🔥 نبضك عالي من الحماس!";
    if (heartRate > 60) return "💖 نبضك هادي وجميل";
    return "😌 نبضك هادئ جداً";
  }

  @override
  void dispose() {
    scanSub?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.redAccent],
            begin: Alignment.topCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: heartRate > 0 ? 200 : 140,
              width: heartRate > 0 ? 200 : 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: heartRate > 0 ? 10 : 2,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 50),
                  Text(
                    heartRate > 0 ? "$heartRate" : "...",
                    style: const TextStyle(
                        fontSize: 45,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text("BPM", style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                getMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w300),
              ),
            ),
            const SizedBox(height: 30),
            if (heartRate == 0 && !isConnecting)
              ElevatedButton.icon(
                onPressed: startListening,
                icon: const Icon(Icons.bluetooth),
                label: const Text("ابدأ القياس"),
              ),
          ],
        ),
      ),
    );
  }
}