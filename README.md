# Sajilo Khata Mobile

Sajilo Khata Mobile is a mobile-first, offline-first digital ledger and billing app for MSMEs in Nepal. It helps users manage customers, track credit and payments, generate invoices, apply VAT calculations, and sync data with Firebase when online. It is built with Flutter for fast, reliable everyday business use.

## Features

- **Dashboard** – today's sales, outstanding credit, low-stock alerts, recent khata activity
- **Billing** – cart with stock checks, 13% Nepal VAT, cash / credit / online payment, receipt shared via WhatsApp
- **Inventory** – search, add/edit/delete products, quick stock adjustment, low-stock highlighting
- **Khata ledger** – per-customer balance, give credit / receive payment, SMS payment reminders (Sparrow SMS)
- **Offline-first** – everything is stored in SQLite on the device; records are pushed to Cloud Firestore on sync
- Nepali / English UI, light & dark themes

## Tech Stack

- Flutter / Dart, Riverpod, SQLite (sqflite)
- Firebase Authentication & Cloud Firestore
- HTML, CSS and JavaScript (Vite) for the web prototype

## Project Structure

| Path | What it is |
| --- | --- |
| `sajilo_khata_mobile/` | Flutter app (Android / iOS / web) — the product |
| `index.html`, `app.js`, `db.js`, `locales.js`, `sparrow_sms.js`, `style.css` | Vite web prototype (localStorage-backed demo) |
| `firebase.json` | Firebase Hosting config for the web prototype |

## Getting Started

### Prerequisites

- Flutter SDK (includes Dart)
- Android Studio (Android) or Xcode (iOS) to run on a device or emulator
- A Firebase project, only if you want phone OTP login and cloud sync

### Run the Flutter app

```bash
git clone https://github.com/aashutosh-k-das/Sajilo_Khata_Mobile.git
cd Sajilo_Khata_Mobile/sajilo_khata_mobile
flutter pub get
flutter run              # or: flutter run -d chrome
```

Without Firebase configuration the app runs in **local offline mode**: login accepts any Nepal mobile
number with the developer OTP `123456`, and all data stays on the device.

On web the database runs on sqlite3 wasm. `web/sqlite3.wasm` must match the resolved `sqlite3`
package version in `pubspec.lock`; if they differ, the app shows a blank page.

### Enabling Firebase (phone OTP login + cloud sync)

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # writes google-services.json / GoogleService-Info.plist
```

Enable **Phone** sign-in in Firebase Authentication and create a Firestore database. Synced data is
written to `shops/{uid}/{bills,transactions,customers,inventory}`. Tap the Online indicator in the app
bar to sync.

### Sparrow SMS reminders

```bash
flutter run --dart-define=SPARROW_SMS_TOKEN=your_token
```

Without a token, reminders open the phone's SMS app with the message pre-filled.

### Tests

```bash
flutter test
```

### Build

```bash
flutter build apk        # Android
flutter build web        # Web
```

## Running the web prototype

```bash
npm install
npm run dev        # http://localhost:3000
npm run build      # outputs dist/ for Firebase Hosting
```

Use OTP `123456` (or the mock Gmail login) to sign in.

## Contributing

Contributions are welcome. Feel free to open issues or submit pull requests for improvements, bug fixes, and feature additions.

## License

Add your project license here if you want to define how others can use the code.

## Image 

<img width="404" height="845" alt="Screenshot 2026-07-02 at 12 20 59 PM" src="https://github.com/user-attachments/assets/68c5ccd7-9098-4d3f-b66c-cc481ac038c4" />
<img width="412" height="843" alt="Screenshot 2026-07-02 at 12 26 30 PM" src="https://github.com/user-attachments/assets/79f3545f-2f70-48a8-a6b9-28b6fcad9780" />
<img width="417" height="846" alt="Screenshot 2026-07-02 at 12 26 45 PM" src="https://github.com/user-attachments/assets/6e5001f5-577c-47b0-abf0-a86ab2c07b25" />
<img width="424" height="858" alt="Screenshot 2026-07-02 at 12 27 10 PM" src="https://github.com/user-attachments/assets/8c83e1bc-3db4-4e69-9dee-7feff12c10f7" />
<img width="416" height="856" alt="Screenshot 2026-07-02 at 12 27 31 PM" src="https://github.com/user-attachments/assets/c601e4b3-d5c0-475b-9613-88b464097467" />
<img width="411" height="851" alt="Screenshot 2026-07-02 at 12 27 40 PM" src="https://github.com/user-attachments/assets/f8cb5ba8-7cb4-46d3-9e1c-b5ff77916a98" />
