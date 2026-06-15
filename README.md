 
<div align="center">

# 💓 Heart Rate Monitor

> *A Flutter app that reads your heart rate in real-time via Bluetooth Low Energy*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![BLE](https://img.shields.io/badge/Bluetooth%20LE-Enabled-4A90D9?style=for-the-badge&logo=bluetooth&logoColor=white)
![License](https://img.shields.io/badge/Made%20with-❤️-red?style=for-the-badge)

</div>

---

## ✨ Overview

A Flutter mobile app that connects to a **K8 smartwatch** via **Bluetooth Low Energy** to display your heart rate live on screen — with animated visuals and motivational messages that update with every new reading.

 
 | | | |
|---|---|---|
| <img src="img width="738" height="1600" alt="1" src="https://github.com/user-attachments/assets/1bb66219-8080-4677-852a-6bd31da84551"
 " width="200" />
  | <img src="https://github.com/user-attachments/assets/907ac1a9-f8fd-4020-b191-bbd64d7a42e5" width="300"/> | <img src="https://github.com/user-attachments/assets/e4e208d5-615e-432a-a88a-8aa508bd29aa" width="300"/> |
| <img src="https://github.com/user-attachments/assets/9b16bd9f-cb90-4355-9b33-509171cf465c" width="300"/> | <img src="https://github.com/user-attachments/assets/b8845f75-790d-4a4d-b045-9bf8b6c806c0" width="300"/> | <img src="https://github.com/user-attachments/assets/bce32ae7-a27e-4cc8-9880-a18d34b5c47d" width="300"/> |

 د
 
```
K8 Watch  ──BLE──▶  App  ──▶  Live BPM Display + Motivational Message
```

---

## 📱 Features

| Feature | Details |
|---|---|
| 🔵 **Auto BLE Connection** | Automatically scans and connects to the K8 watch |
| 💗 **Live Heart Rate** | Displays real-time BPM readings |
| 💬 **Motivational Messages** | 14 messages that rotate with every new reading |
| 🎨 **Animated UI** | Glowing circle that pulses with each heartbeat |
| 🔋 **Low Power** | Uses BLE Notifications instead of polling |
| 🌙 **Dark Theme** | Smooth black-to-red gradient design |

---

## 🛠️ Tech Stack

```yaml
dependencies:
  flutter_blue_plus: 1.14.0      # Bluetooth LE communication
  permission_handler: ^12.0.1    # Runtime permissions
  lottie: ^3.2.0                 # Animations (for future use)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `≥ 3.0`
- Android or iOS device with Bluetooth 4.0+
- **K8 smartwatch**

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/heart-rate-monitor.git

# 2. Navigate to the project
cd heart-rate-monitor

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

---

## 🔐 Required Permissions

<details>
<summary>Android — <code>AndroidManifest.xml</code></summary>

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

</details>

<details>
<summary>iOS — <code>Info.plist</code></summary>

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth to connect to your smartwatch</string>
```

</details>

---

## 🧠 How It Works

```
┌─────────────────────────────────────────────┐
│               App Lifecycle                 │
├─────────────────────────────────────────────┤
│                                             │
│  [Launch]  ──▶  Request Permissions         │
│                 │                           │
│                 ▼                           │
│           [Start Button]  ──▶  BLE Scan     │
│                 │              (20 seconds) │
│                 ▼                           │
│           K8 Discovered  ──▶  Stop Scan     │
│                 │                           │
│                 ▼                           │
│           Connect to Device                 │
│                 │                           │
│                 ▼                           │
│           Discover Services                 │
│        ┌────────┴─────────┐                │
│        ▼                  ▼                │
│    WriteChar          NotifyChar           │
│    (ff02)             (6e400003)           │
│        │                  │                │
│        ▼                  ▼                │
│   Send Command       Receive Data          │
│   [15, 01, 01]       Validate Range        │
│                       (40–200 BPM)         │
│                            │               │
│                            ▼               │
│                    Update UI               │
│                  + New Message             │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎨 UI Layout

```
┌──────────────────────┐
│    Connection Status  │  ← Status text
│                       │
│    ┌──────────┐       │
│    │  ❤️       │       │
│    │  72 BPM  │       │  ← Glowing AnimatedContainer
│    └──────────┘       │
│                       │
│  "You're stronger     │
│   than you think! 💪" │  ← Rotating motivational message
│                       │
│  [ Start Measuring ]  │  ← Hidden once connected
└──────────────────────┘
```

---

## 📊 Heart Rate Data Handling

Each `value` arriving from the watch is a `List<int>`. The app only accepts a reading if:

```dart
value.length == 1 && value[0] >= 40 && value[0] <= 200
```

> This filter ignores noise, calibration packets, and out-of-range garbage data.

---

## 🔮 Roadmap

- [ ] Heart rate history chart over time
- [ ] Alerts when BPM exceeds a threshold
- [ ] Lottie animation for a more lifelike heartbeat
- [ ] Support for additional BLE smartwatches
- [ ] Local session storage and history

---

<div align="center">

*"Nothing is impossible when the will is strong enough"* ⚡

</div>
