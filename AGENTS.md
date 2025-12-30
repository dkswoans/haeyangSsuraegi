# Repository Guidelines

## Project Structure & Module Organization
Source lives in `lib/` with `lib/main.dart` as the app entry point. Domain models are in `lib/models/` (e.g., `photo_record.dart`), data and persistence helpers in `lib/services/`, and Riverpod controllers in `lib/state/`. UI screens are organized in `lib/ui/screens/` with shared widgets in `lib/ui/widgets/`. Assets such as `assets/placeholder.png` are declared in `pubspec.yaml`. Tests are in `test/`, and platform runners are in `android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/`.

## Build, Test, and Development Commands
- `flutter pub get` - install dependencies.
- `flutter run` - run on a connected device or emulator.
- `flutter analyze` - run static analysis using `analysis_options.yaml`.
- `flutter test` - run unit and widget tests in `test/`.
- `flutter build apk` / `flutter build ios` / `flutter build web` - produce release builds.
- `dart format .` - apply Dart formatting (2-space indentation).

## Coding Style & Naming Conventions
Use Dart and Flutter defaults enforced by `flutter_lints`. File names are `lower_snake_case.dart`; classes and enums use `UpperCamelCase`; variables, methods, and fields use `lowerCamelCase`. Keep UI code in `lib/ui/` and state logic in `lib/state/` to match the existing layering.

## Testing Guidelines
Tests use `flutter_test`. Name files `*_test.dart` in `test/` and add widget tests for new screens plus controller tests for new state logic. There is no explicit coverage target; use `flutter test --coverage` when adding significant features or bug fixes.

## Commit & Pull Request Guidelines
Recent Git history uses short, informal messages (date stamps like `20251229` and brief phrases). Keep commits concise and consistent with that pattern unless the team agrees to adopt a different convention. Pull requests should include a summary, the test command run (or "not run" with reason), and screenshots or GIFs for UI changes. Link related issues when applicable.
