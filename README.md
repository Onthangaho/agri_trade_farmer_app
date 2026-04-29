# AgriTrade Farmer App

AgriTrade is a mobile app built for farmers to list crops, manage farm details, and connect with buyers through a simple marketplace.
The app is designed for real-life conditions where internet is not always stable. It saves important data locally and syncs to the cloud when connection is available.

## What This App Does

- Lets farmers create and manage crop listings
- Shows all listed crops in a marketplace view
- Allows farmers to update profile and farm information
- Supports picking crop images from camera or gallery
- Tracks connectivity and shows sync status
- Works in an offline-first way using local storage + background sync

## Main Features

### 1) Authentication
- Register new farmer account
- Login and logout
- Forgot password flow

### 2) Crop Management
- Add crop listings with:
  - crop name
  - category
  - quantity
  - price
  - expiry date
  - image
- Edit and delete existing crops
- View detailed crop information

### 3) Marketplace
- Browse crop listings from farmers
- Search/filter listings
- Open crop details from marketplace cards

### 4) Farm & Profile
- Save and edit farmer profile details
- Update profile image
- Tag farm location with GPS support

### 5) Offline + Sync
- Local SQLite storage for important app data
- Sync queue for pending operations
- Background sync task (WorkManager)
- Live connectivity and sync status in Settings

### 6) Settings
- Light / Dark / System theme selection
- Manual "Sync Now"
- Connectivity refresh and last sync info

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Dependency Injection:** GetIt
- **Backend:** Firebase Auth + Cloud Firestore
- **Local Database:** SQLite (`sqflite`)
- **Background Work:** WorkManager
- **Image Handling:** `image_picker`, `flutter_image_compress`
- **Location:** `geolocator`, `geocoding`

## Project Structure

The project uses a feature-first structure:

- `lib/features/auth` - login, register, forgot password
- `lib/features/crops` - add/edit/view crops
- `lib/features/marketplace` - marketplace listing screens
- `lib/features/farms` - farm location and farm data
- `lib/features/profile` - profile view/edit
- `lib/shared` - shared widgets, providers, database helpers
- `lib/core` - app services, theme, constants, utilities
- `lib/routes` - app routes/navigation

## How to Run the App

### Requirements
- Flutter SDK (latest stable recommended)
- Android Studio or VS Code
- Android device or emulator
- Firebase project configured for this app

### Setup Steps

1. Clone this repo
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Make sure Firebase config files are in place (already expected in this project setup)
4. Run the app:
   ```bash
   flutter run
   ```

To run on a specific device:
```bash
flutter devices
flutter run -d <device_id>
```

## Demo Flow 

1. Login/Register
2. Open Marketplace and show available crops
3. Go to My Crops and add a new crop with image
4. Open the crop details screen
5. Show My Farm and location tagging
6. Open Settings and show:
   - theme switching
   - connectivity status
   - manual sync

## Notes

- The app is focused on practical farmer use cases.
- It is built to handle weak/unstable internet conditions.
- Data is synced safely when connectivity returns.

## Future Improvements

- Push notifications for expiring listings
- Better in-app messaging between farmers and buyers
- Improved analytics/dashboard for sales and listings
- Multi-language expansion

## Author

Built by me as part of my trainee program project.
