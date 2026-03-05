# 🏠 Mana Kiraa - House Rental App

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com)

**Mana Kiraa** is a premium, modern mobile application designed to bridge the gap between property owners and house hunters. Built with **Flutter**, it offers a seamless, high-performance experience across both Android and iOS.

---

## ✨ Key Features

- **🔍 Smart Property Search**: Filter and find properties based on location, price, and type.
- **📱 Modern UI/UX**: clean, intuitive interface with smooth animations and dark mode support.
- **🔔 Real-time Notifications**: Stay updated with push notifications for new listings and messages.
- **🔐 Secure Authentication**: Easy and secure login via Google Sign-In and Supabase Auth.
- **💖 Favorites & Wishlists**: Save your favorite properties to review them later.
- **📸 High-Quality Galleries**: Browse beautiful property images with optimized caching.
- **📍 Location Awareness**: Integrated maps and location services for easy navigation.

---

## 🚀 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Language**: [Dart](https://dart.dev)
- **Backend-as-a-Service**: [Supabase](https://supabase.com) (Database, Storage, Auth)
- **Push Notifications**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **State Management**: Provider / Simple State Management (Core architecture)
- **External Integrations**: Google Sign-In, URL Launcher, Image Picker

---

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- A Supabase project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AMANI-BLU/ManaKiraa.git
   cd ManaKiraa
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   Ensure your Supabase and Firebase configurations are correctly set up in the project (check `lib/core/supabase_config.dart` or similar).

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```text
lib/
├── core/       # App themes, constants, and utilities
├── data/       # Data providers and repositories
├── models/     # Data models
├── screens/    # UI screens (Home, Profile, Search, etc.)
└── main.dart   # App entry point
```

---

## 📝 License

This project is private and intended for the Mana Kiraa platform.

---

Built with ❤️ by the Mana Kiraa Team.
