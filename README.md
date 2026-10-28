# Sajilo_Khata_Mobile
Sajilo Khata Mobile is a mobile-first, offline-first digital ledger and billing app for MSMEs in Nepal. It helps users manage customers, track credit and payments, generate invoices, apply VAT calculations, and sync data with Firebase when online. It is built with Flutter for fast, reliable everyday business use.

## Repository layout

| Path | What it is |
| --- | --- |
| `sajilo_khata_mobile/` | Flutter app (Android / iOS) — the product |
| `index.html`, `app.js`, `db.js`, `locales.js`, `style.css` | Vite web prototype (localStorage-backed demo) |

## Features

- **Dashboard** – today's sales, outstanding credit, low-stock alerts, recent khata activity
- **Billing** – cart with stock checks, 13% Nepal VAT, cash / credit / online payment, receipt shared via WhatsApp
- **Inventory** – search, add/edit/delete products, quick stock adjustment, low-stock highlighting
- **Khata ledger** – per-customer balance, give credit / receive payment, SMS payment reminders (Sparrow SMS)
- **Offline-first** – everything is stored in SQLite on the device; records are pushed to Cloud Firestore on sync
- Nepali / English UI, light & dark themes

## Running the Flutter app

```bash
cd sajilo_khata_mobile
flutter pub get
flutter run
```

Without Firebase configuration the app runs in **local offline mode**: login accepts any Nepal mobile
number with the developer OTP `123456`, and all data stays on the phone.

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

## Running the web prototype

```bash
npm install
npm run dev        # http://localhost:3000
npm run build      # outputs dist/ for Firebase Hosting
```

Use OTP `123456` (or the mock Gmail login) to sign in.
