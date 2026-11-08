# 🚌 SafeWay App — Smart School Bus System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)

> **Real-time tracking and notifications for safe, organized school transportation.**

</div>

---

## 📖 About

SafeWay is a smart school bus management system designed for a school environment. The app allows **students**, **parents**, **drivers**, and **admins** to manage and track school buses in real time.

This repository contains the **Flutter mobile application** that connects to the SafeWay .NET backend API.

---

## 📱 Screens

| Screen | Role | Description |
|--------|------|-------------|
| 🏠 Role Selection | All | Choose your role to login |
| 🔐 Login | All | Login with your unique ID and password |
| 📝 Sign Up | Student / Parent | Create a new account |
| 👨‍👩‍👧 Parent Dashboard | Parent | Monitor children and bus activity |
| 🗺️ Live Bus Tracking | All | Real-time bus location on map |
| 🚌 Driver Dashboard | Driver | Manage routes and confirm boardings |
| 🎓 Student Dashboard | Student | Track bus and view routes |
| ⚙️ Admin Dashboard | Admin | Manage users, drivers and routes |

---

## 👥 Roles

| Role | Unique ID Format | Example |
|------|-----------------|---------|
| 🧑‍🎓 Student | STU + number | STU001 |
| 👨‍👩‍👧 Parent | PAR + number | PAR001 |
| 🚌 Driver | DRV + number | DRV001 |
| 🔐 Admin | Admin | Admin |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter |
| Language | Dart |
| Maps | Flutter Map (OpenStreetMap) |
| Location | Geolocator |
| Auth | JWT Token |
| Storage | Flutter Secure Storage |
| HTTP | http package |
| Backend | .NET REST API |

---

## 📦 Packages Used

```yaml
dependencies:
  flutter_map: latest
  latlong2: latest
  geolocator: latest
  http: latest
  flutter_secure_storage: latest
```

---

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/hussincode/App_SafeWay.git
cd App_SafeWay
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Connect to the backend

Open `lib/services/api_config.dart` and update the base URL if needed:

```dart
String get apiBaseUrl {
  return 'http://safewayback.runasp.net';
}
```

To find your PC IP run:
```bash
ipconfig
```
Look for **IPv4 Address** under your WiFi adapter.

### 4. Run the app

```bash
flutter run
```

---

## 📂 Project Structure

```
lib/
├── screens/
│   ├── role_selection_screen.dart
│   ├── login_screen_parents.dart
│   ├── student_signup_screen.dart
│   ├── parent_dashboard_screen.dart
│   ├── live_bus_tracking_screen.dart
│   └── ...
├── services/
│   └── auth_service.dart
└── main.dart
```

---

## 🔐 How Login Works

```
User enters ID + Password
        ↓
Flutter sends request to .NET API
        ↓
API checks database and verifies password
        ↓
API returns JWT Token + Role
        ↓
Flutter saves token securely
        ↓
Flutter navigates to the right dashboard
```

---

## 🗺️ Live Bus Tracking

- Uses **OpenStreetMap** via Flutter Map — no API key needed
- Driver shares real GPS location every 5 seconds
- Parents and students see the bus moving on the map in real time
- Shows Distance, ETA, and Speed

---

## ⚙️ Android Permissions

The following permissions are required in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 🔗 Connected Backend

This app connects to the **SafeWay .NET API**:

👉 [Backend Repository](https://github.com/hussincode/SafeWayBack)

---

## 👨‍💻 Developer

Built by **SafeWay Team** — Computer Science Capstone Project

---

## 📄 License

This project is for educational purposes as part of a capstone project.
