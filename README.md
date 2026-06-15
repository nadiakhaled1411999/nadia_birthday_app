# nadia_birthday_app

 <div align="center">

# 💓 Nadia Heart Monitor

> *تطبيق Flutter لقياس نبض القلب عبر Bluetooth — مصنوع بالحب، لنادية*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![BLE](https://img.shields.io/badge/Bluetooth%20LE-Enabled-4A90D9?style=for-the-badge&logo=bluetooth&logoColor=white)
![License](https://img.shields.io/badge/Made%20with-❤️-red?style=for-the-badge)

</div>

---

## ✨ نظرة عامة

تطبيق موبايل مبني بـ **Flutter** يتصل بساعة ذكية (طراز K8) عبر **Bluetooth Low Energy** لعرض معدل نبض القلب لحظةً بلحظة — مع رسائل تحفيزية شخصية لمرافقتك أثناء المذاكرة.

```
الساعة K8  ──BLE──▶  التطبيق  ──▶  عرض النبض + رسالة تحفيز
```

---

## 📱 مميزات التطبيق

| الميزة | التفاصيل |
|---|---|
| 🔵 **اتصال BLE تلقائي** | يبحث ويتصل بساعة K8 تلقائيًا |
| 💗 **نبض لحظي** | يعرض BPM في الوقت الفعلي |
| 💬 **رسائل تحفيزية** | 14 رسالة تتغير مع كل قراءة جديدة |
| 🎨 **تصميم متحرك** | دائرة تكبر وتتوهج مع كل نبضة |
| 🔋 **استهلاك منخفض** | يستخدم BLE Notifications لا polling |
| 🌙 **ثيم داكن** | تدرج لوني من الأسود إلى الأحمر |

---

## 🛠️ التقنيات المستخدمة

```yaml
dependencies:
  flutter_blue_plus: 1.14.0      # الاتصال بـ Bluetooth LE
  permission_handler: ^12.0.1    # طلب صلاحيات النظام
  lottie: ^3.2.0                 # الرسوم المتحركة (للتطوير المستقبلي)
```

---

## 🚀 كيفية تشغيل المشروع

### المتطلبات الأساسية

- Flutter SDK `≥ 3.0`
- هاتف Android أو iOS يدعم Bluetooth 4.0+
- ساعة ذكية طراز **K8**

### خطوات التثبيت

```bash
# 1. استنساخ المستودع
git clone https://github.com/your-username/nadia-heart-monitor.git

# 2. الدخول للمجلد
cd nadia-heart-monitor

# 3. تثبيت الحزم
flutter pub get

# 4. تشغيل التطبيق
flutter run
```

---

## 🔐 الصلاحيات المطلوبة

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
<string>نحتاج Bluetooth للاتصال بالساعة الذكية</string>
```

</details>

---

## 🧠 كيف يعمل التطبيق؟

```
┌─────────────────────────────────────────────┐
│              دورة حياة التطبيق              │
├─────────────────────────────────────────────┤
│                                             │
│  [بدء]  ──▶  طلب الصلاحيات                │
│              │                              │
│              ▼                              │
│         [زر البدء]  ──▶  Scan BLE          │
│              │            (20 ثانية)        │
│              ▼                              │
│         اكتشاف K8  ──▶  قطع المسح          │
│              │                              │
│              ▼                              │
│         الاتصال بالجهاز                    │
│              │                              │
│              ▼                              │
│       استكشاف الخدمات                      │
│    ┌────────┴─────────┐                    │
│    ▼                  ▼                    │
│  WriteChar          NotifyChar             │
│  (ff02)             (6e400003)             │
│    │                  │                    │
│    ▼                  ▼                    │
│  إرسال أمر       استقبال البيانات          │
│  [15, 01, 01]    والتحقق من النطاق         │
│                  (40–200 BPM)              │
│                       │                    │
│                       ▼                    │
│               تحديث الواجهة               │
│             + رسالة تحفيز جديدة           │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎨 تصميم الواجهة

```
┌──────────────────────┐
│    حالة الاتصال      │  ← نص الحالة (Status)
│                      │
│    ┌──────────┐      │
│    │  ❤️      │      │
│    │  72 BPM  │      │  ← دائرة متوهجة (AnimatedContainer)
│    └──────────┘      │
│                      │
│  "شدي حيلك يا        │
│   نادية! 💪"         │  ← رسالة تحفيزية متغيرة
│                      │
│  [ ابدأ القياس ]     │  ← يختفي عند الاتصال
└──────────────────────┘
```

---

## 📊 معالجة بيانات النبض

يصل كل `value` من الساعة كـ `List<int>`. التطبيق يقبل القيمة فقط إذا:

```dart
value.length == 1 && value[0] >= 40 && value[0] <= 200
```

> هذا الفلتر يتجنب القيم الخاطئة أو بيانات المعايرة الأولية.

---

## 💬 الرسائل التحفيزية

يحتوي التطبيق على **14 رسالة** تتناوب تلقائيًا مع كل قراءة نبض جديدة:

> *"أوعي تستسلمي يا نادية، تعبك عمره ما هيضيع!"*
> *"التعب ده مؤقت، النجاح ده للأبد!"*
> *"ربنا مش بيضيع أجر المجتهدين، شدي حيلك!"*

---

## 🔮 تطويرات مستقبلية

- [ ] رسم بياني لمعدل النبض عبر الزمن  
- [ ] إشعارات عند تجاوز حد معين  
- [ ] تكامل Lottie لتحريك القلب بشكل أكثر واقعية  
- [ ] دعم ساعات BLE إضافية  
- [ ] حفظ سجل القياسات محليًا  

---

## 🤍 من صنعه؟

صُنع هذا التطبيق بـ **Flutter** و**محبة كثير** — لنادية، حتى لا تنسى أن كل لحظة مذاكرة تستحق.

---

<div align="center">

*"مفيش حاجة اسمها مستحيل لما الإرادة تكون قوية"* ⚡

</div>
