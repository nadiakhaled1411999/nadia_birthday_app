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
  bool _alreadyConnecting = false;
  int _messageIndex = 0;

  final List<String> _messages = [
    "أوعي تستسلمي يا نادية، تعبك عمره ما هيضيع! 💪",
    "تعبتي من المذاكرة؟ افتكري لحظة وصولك هتنسيكي كل تعب! 🌟",
    "كل ساعة بتذاكريها دي خطوة أقرب للحلم! 📚",
    "النجاح مش بييجي لوحده، إنتي بتبنيه دلوقتي! ✨",
    "صعبة بس مش مستحيلة، إنتي أقوى من إنك تستسلمي! 🔥",
    "ربنا مش غافل عنك يا نادية، كل تعبك محسوب! ❤️",
    "إنتي مش بتذاكري لنفسك بس، في ناس بتحلم بنجاحك! 🌈",
    "التعب ده مؤقت، النجاح ده للأبد! 🏆",
    "شدي حيلك يا نادية، الفجر قريب! 🌅",
    "كل دقيقة بتذاكريها دي استثمار في مستقبلك! 💡",
    "إنتي بطلة حتى لو مش حاسة بده دلوقتي! 🦋",
     "ربنا مش بيضيع أجر المجتهدين، شدي حيلك! 💫",
    "مفيش حاجة اسمها مستحيل لما الإرادة تكون قوية! ⚡",
    "فكري في هدفك وهيبقى كل حاجة أسهل! 🎯",
  ];

  StreamSubscription? scanSub;
  StreamSubscription? hrSub;
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
      _alreadyConnecting = false;
      status = "جاري البحث عن الساعة...";
    });

    scanSub?.cancel();
    hrSub?.cancel();

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (_alreadyConnecting) return;
      for (ScanResult r in results) {
        final name = r.advertisementData.localName.trim();
        // ignore: deprecated_member_use
        final deviceName = r.device.name.trim();
        if (name.contains("K8") || deviceName.contains("K8")) {
          _alreadyConnecting = true;
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
              _alreadyConnecting = false;
            });
          }
        }
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      for (var service in services) {
        for (var char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid.contains("ff02")) writeChar = char;
          if (uuid.contains("6e400003")) notifyChar = char;
        }
      }

      if (notifyChar != null) {
        await notifyChar.setNotifyValue(true);

        hrSub = notifyChar.lastValueStream.listen(
          (value) {
            if (value.isEmpty) return;
            if (value.length == 1 && value[0] >= 40 && value[0] <= 200) {
              if (mounted) {
                setState(() {
                  heartRate = value[0];
                  status = "متصل بالساعة ❤️";
                  _messageIndex++; // ✅ رسالة جديدة مع كل قياس
                });
              }
            }
          },
          onError: (e) => print("❌ error: $e"),
          cancelOnError: false,
        );
      }

      if (writeChar != null) {
        await writeChar.write([0x15, 0x01, 0x01], withoutResponse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          status = "فشل الاتصال: $e";
          isConnecting = false;
          _alreadyConnecting = false;
        });
      }
    }
  }

  String getMessage() {
    if (heartRate == 0) return "مستعدين نبدأ؟ 😊";
    return _messages[_messageIndex % _messages.length];
  }

  @override
  void dispose() {
    hrSub?.cancel();
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
