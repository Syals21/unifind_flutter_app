# UniFind

UniFind is a campus lost and found mobile application built with Flutter, PHP,
and SQLite. Students can register, log in, browse reports, search and filter
items, create lost or found reports, update their own reports, mark items as
claimed, and delete their own reports.

## Technology

- Flutter frontend
- PHP JSON API
- SQLite database through PHP PDO
- Apache from XAMPP

## Project Structure

```text
lib/
  models/
  services/
  views/
  widgets/
server/unifind/
  api/
  uploads/reports/
```

The included database is `server/unifind/api/unifind.db`.

## Run the Backend

1. Copy `server/unifind` to `C:\xampp\htdocs\unifind`.
2. Start Apache in the XAMPP Control Panel.
3. Open `http://localhost/unifind/api/load_reports.php`.

The backend is already deployed at `C:\xampp\htdocs\unifind` on the development
computer.

## Run the Flutter App

1. Start the Pixel emulator in Android Studio.
2. Keep Apache running in XAMPP.
3. From this project folder, run:

```text
flutter pub get
flutter run
```

Android emulator requests use `http://10.0.2.2/unifind/api`.

## Demo Account

```text
Email: student@unifind.com
Password: student123
```

## API Endpoints

- `register.php` - create an account
- `login.php` - authenticate a user
- `load_reports.php` - list, search, filter, and paginate reports
- `add_report.php` - create a report
- `update_report.php` - edit a report or update its status
- `delete_report.php` - delete a user's own report
- `update_profile.php` - update name and phone number

## Verification

```text
flutter analyze
flutter test
flutter build apk --debug
```
