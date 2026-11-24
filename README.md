# Expense Tracker (Flutter, Android)

Offline expense tracker. No account, no server, data stays on the phone.

## Features

- Expenses and income, with category, note, date and payment method
- Month switcher, search, filter by type, entries grouped by day in expandable cards
- Swipe left to delete with undo, tap to edit
- Monthly budget with a live "safe to spend per day" figure
- Per category monthly limits with progress bars that turn orange then red
- Custom categories with your own icon and colour
- Recurring entries (weekly or monthly) that log themselves
- Stats: category donut, day by day bars, income vs spent over 6 months, averages
- Light, dark or system theme plus accent colour
- Custom currency label (default UGX)
- CSV export, JSON backup and restore

## Run locally

```bash
flutter create --platforms=android --org com.devn1n --project-name expense_tracker .
flutter pub get
flutter run
```

`flutter create .` only adds the missing `android/` folder. It does not touch `lib/`.
You can commit the generated `android/` folder afterwards, the CI skips generating it if it exists.

## Release APK on GitHub

Push a tag and the workflow builds the APK and attaches it to a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

You can also run it by hand from the Actions tab (Run workflow). It then uses the
version in `pubspec.yaml` as the tag.

### Keep updates installable (recommended, one time)

Without this, every CI build is signed with a fresh random key, and Android refuses to
install a new APK over an older one. Fix it by storing one keystore as a secret:

```bash
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey \
  -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
base64 -w0 debug.keystore   # macOS: base64 -i debug.keystore
```

Add the output as a repository secret named `DEBUG_KEYSTORE_BASE64`
(Settings, Secrets and variables, Actions). Keep the file safe, never commit it.
This is fine for personal use. For the Play Store you need a proper upload key.
