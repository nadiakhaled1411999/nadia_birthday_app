import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(const FlutterHeartApp());

// Constants
const String _targetDeviceName = 'K8';
const String _notifyCharUuid = '6e400003';
const String _writeCharUuid = 'ff02';
const int _heartRateMin = 40;
const int _heartRateMax = 200;
const List<int> _heartRateCommand = [0x15, 0x01, 0x01];

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
  int _heartRate = 0;
  String _status = 'اضغطي للبحث عن ساعتك';
  bool _isConnecting = false;
  bool _alreadyConnecting = false;
  int _messageIndex = 0;

  StreamSubscription? _scanSub;
  StreamSubscription? _hrSub;
  BluetoothDevice? _connectedDevice;

  // Added motivational messages that change with each new heart rate reading
  static const List<String> _messages = [
    'أوعي تستسلمي يا نادية، تعبك عمره ما هيضيع! 💪',
    'تعبتي من المذاكرة؟ افتكري لحظة وصولك هتنسيكي كل تعب! 🌟',
    'كل ساعة بتذاكريها دي خطوة أقرب للحلم! 📚',
    'النجاح مش بييجي لوحده، إنتي بتبنيه دلوقتي! ✨',
    'صعبة بس مش مستحيلة، إنتي أقوى من إنك تستسلمي! 🔥',
    'ربنا مش غافل عنك يا نادية، كل تعبك محسوب! ❤️',
    'إنتي مش بتذاكري لنفسك بس، في ناس بتحلم بنجاحك! 🌈',
    'التعب ده مؤقت، النجاح ده للأبد! 🏆',
    'شدي حيلك يا نادية، الفجر قريب! 🌅',
    'كل دقيقة بتذاكريها دي استثمار في مستقبلك! 💡',
    'إنتي بطلة حتى لو مش حاسة بده دلوقتي! 🦋',
    'ربنا مش بيضيع أجر المجتهدين، شدي حيلك! 💫',
    'مفيش حاجة اسمها مستحيل لما الإرادة تكون قوية! ⚡',
    'فكري في هدفك وهيبقى كل حاجة أسهل! 🎯',
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  bool _isTargetDevice(ScanResult r) {
    final localName = r.advertisementData.localName.trim();
    // ignore: deprecated_member_use
    final deviceName = r.device.name.trim();
    return localName.contains(_targetDeviceName) ||
        deviceName.contains(_targetDeviceName);
  }

  void _startListening() async {
    setState(() {
      _isConnecting = true;
      _alreadyConnecting = false;
      _status = 'جاري البحث عن الساعة...';
    });

    _scanSub?.cancel();
    _hrSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (_alreadyConnecting) return;
      for (final r in results) {
        if (_isTargetDevice(r)) {
          _alreadyConnecting = true;
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _connectToClock(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
  }

  Future<void> _connectToClock(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      await device.connect(timeout: const Duration(seconds: 20));
      if (mounted) setState(() => _status = 'جاري قياس النبض... ⏳');

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && mounted) {
          setState(() {
            _status = 'تم فصل الاتصال';
            _heartRate = 0;
            _isConnecting = false;
            _alreadyConnecting = false;
          });
        }
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      for (final service in services) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid.contains(_writeCharUuid)) writeChar = char;
          if (uuid.contains(_notifyCharUuid)) notifyChar = char;
        }
      }

      if (notifyChar != null) {
        await notifyChar.setNotifyValue(true);
        _hrSub = notifyChar.lastValueStream.listen(
          _onHeartRateReceived,
          cancelOnError: false,
        );
      }

      await writeChar?.write(_heartRateCommand, withoutResponse: true);

    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'فشل الاتصال: $e';
          _isConnecting = false;
          _alreadyConnecting = false;
        });
      }
    }
  }

  void _onHeartRateReceived(List<int> value) {
    if (value.isEmpty) return;
    if (value.length == 1 &&
        value[0] >= _heartRateMin &&
        value[0] <= _heartRateMax) {
      if (mounted) {
        setState(() {
          _heartRate = value[0];
          _status = 'متصل بالساعة ❤️';
          _messageIndex++;
        });
      }
    }
  }

  String _getMessage() {
    if (_heartRate == 0) return 'مستعدين نبدأ؟ 😊';
    return _messages[_messageIndex % _messages.length];
  }

  @override
  void dispose() {
    _hrSub?.cancel();
    _scanSub?.cancel();
    _connectedDevice?.disconnect();
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
            Text(_status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: _heartRate > 0 ? 200 : 140,
              width: _heartRate > 0 ? 200 : 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: _heartRate > 0 ? 10 : 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 50),
                  Text(
                    _heartRate > 0 ? '$_heartRate' : '...',
                    style: const TextStyle(
                      fontSize: 45,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'BPM',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _getMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_heartRate == 0 && !_isConnecting)
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.bluetooth),
                label: const Text('ابدأ القياس'),
              ),
          ],
        ),
      ),
    );
  }
}