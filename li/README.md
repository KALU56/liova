# Liova Frontend Architecture

Liova is a cross-platform mobile application built using the Flutter framework. It serves as the user-facing interface for cosmetic ingredient scanning, skin analysis, and history tracking.

## Table of Contents
1. [Core Technologies](#core-technologies)
2. [App Architecture & State](#app-architecture--state)
3. [Key Services](#key-services)
4. [Screens & UI Flow](#screens--ui-flow)
5. [Theming & Aesthetics](#theming--aesthetics)

---

## Core Technologies
- **Framework:** Flutter (Dart)
- **Backend Communication:** HTTP REST API
- **Cloud Storage:** Cloudinary (for images)
- **Database:** Firebase Firestore (for history & user profiles)
- **Authentication:** Firebase Auth

---

## App Architecture & State

The app is structured around a service-oriented architecture, keeping UI logic completely separate from backend communication and database storage.
State management is handled primarily using native `StatefulWidget` lifecycle methods along with `StreamBuilder` and `FutureBuilder` to reactively stream data from Firebase.

### Directory Structure
- `lib/screens/`: Contains the primary UI pages (Home, Scan, Result, Auth).
- `lib/services/`: Contains singleton or stateless service classes for external communication.
- `lib/models/`: Contains strongly typed Dart data classes (e.g., `ScanResult`).
- `lib/theme/`: Contains the centralized design system.

---

## Key Services

### 1. `ApiService` (`services/api_service.dart`)
This service acts as the bridge between the Flutter app and the FastAPI backend.
- It determines the correct `baseUrl` depending on the platform (e.g., mapping `10.0.2.2` for Android emulators).
- It handles packaging Base64 images and raw text into JSON payloads.
- It gracefully catches backend errors (like quota exhaustion or 502 Bad Gateway) and throws user-friendly Dart exceptions.

### 2. `CloudinaryService` (`services/cloudinary_service.dart`)
Because the backend API is stateless, image hosting is offloaded to Cloudinary.
- Receives the raw byte array of a captured photo.
- Uses a multipart HTTP POST request to upload the image directly to Cloudinary using an unsigned upload preset.
- Returns a secure public URL (`secure_url`) which is then attached to the `ScanResult` so the user can view the photo later.

### 3. `HistoryService` (`services/history_service.dart`)
A wrapper around Firebase Firestore.
- Exposes an `addScan` method to permanently save a `ScanResult` model to the user's specific collection document.
- Exposes a `watchHistory` method that returns a `Stream<List<ScanResult>>`. This ensures the UI is always completely synchronized with the database in real-time.

---

## Screens & UI Flow

### Home Page (`home_page.dart`)
The dashboard of the application.
- Utilizes a `CustomScrollView` and slivers (`SliverList`, `SliverToBoxAdapter`) to create a smooth, unified scrolling experience.
- Displays a quick CTA banner to launch the scanner.
- Uses a `StreamBuilder` bound to the `HistoryService` to reactively render the user's recent scan history cards.

### Scan Page (`scan_page.dart`)
The core feature interface.
- Implements a `TabBar` to allow users to switch seamlessly between two input methods:
  - **Image Tab:** Integrates the `image_picker` package to open the device camera or gallery.
  - **Text Tab:** Provides a `TextField` for pasting copied ingredients.
- Manages the complex asynchronous flow: 
  1. Capture Image -> 2. Upload to Cloudinary -> 3. Call FastAPI -> 4. Save to Firestore -> 5. Navigate to Results.

### History Page (`history_page.dart`)
A dedicated, fully scrollable list of all past user scans.
- Parses and formats the `createdAt` timestamps into human-readable strings (e.g., "Today, 2:30 PM").
- Displays the physical photo thumbnail downloaded from Cloudinary if an image was used.

---

## Theming & Aesthetics (`app_theme.dart`)

Liova is designed with a premium, soft, and modern aesthetic focused on cosmetics.
- **Color Palette (`LiovaColors`):** Utilizes soft rose gradients, pale background tokens, and semantic safety colors (Teal for safe, Red for caution).
- **Typography (`LiovaText`):** A centralized text scaling system ensuring uniform heading and body font sizes across the app.
- **Decorations (`LiovaDecorations`):** Reusable `BoxDecoration` objects that apply consistent glassmorphism effects, drop shadows, and border radii to all cards and UI elements.
