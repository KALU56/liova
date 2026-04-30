# Lio App

A Flutter mobile app for skincare ingredient analysis using camera scan, Cloudinary image upload, and a Python backend powered by Google Gemini.

## What the app does

- Uses the camera to capture a product label or ingredient list.
- Uploads the captured image to Cloudinary.
- Sends the Cloudinary image URL to the backend `/analyze` endpoint.
- Displays the returned risk analysis, summary, and ingredient results.
- Saves scan history locally on the device.

## Architecture

- `lib/screens/scan/scan_page.dart`
  - captures camera image
  - uploads to Cloudinary using `CloudinaryService`
  - calls backend API via `ApiService`
  - shows analysis results and saves history

- `lib/services/cloudinary_service.dart`
  - uploads images to Cloudinary
  - returns the secure image URL

- `lib/services/api_service.dart`
  - calls backend endpoints
  - currently uses `POST /analyze`

- `lib/services/history_service.dart`
  - stores scan results in local shared preferences
  - loads saved scan history for the history screen

## Configuration

### Cloudinary

The app reads Cloudinary configuration from `lio_app/.env` with these values:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`
- `FASTAPI_BASE_URL`

This file is ignored by Git via `.gitignore`, so secrets stay local.

### Backend URL

The mobile app sends analysis requests to the backend at:

- `http://10.0.2.2:8000` for Android emulator

If you run the backend on a real device or different network, update `_kFastApiBaseUrl` in `lib/screens/scan/scan_page.dart`.

## Run the app

1. Open the Flutter project in your editor.
2. Run `flutter pub get`.
3. Connect an emulator or device.
4. Run `flutter run`.

## App flow

1. Open the scan screen.
2. Tap the capture button to take a photo.
3. The app uploads the photo to Cloudinary.
4. The app sends the returned Cloudinary URL to the backend `/analyze` endpoint.
5. The backend uses Gemini and the local dataset to generate analysis.
6. The app displays the analysis and saves it to history.

## Notes

- History is currently stored locally in `SharedPreferences`.
- If you want remote history in Firebase, the backend and app need additional integration.
