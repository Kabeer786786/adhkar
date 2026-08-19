# Adhkar

> **Your Daily Spiritual Islamic Companion**

<p align="center">
  A free and open-source Islamic companion app designed to make daily worship
  simple, accessible, and distraction-free.
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#screenshots">Screenshots</a> ·
  <a href="#getting-started">Getting Started</a> ·
  <a href="#architecture">Architecture</a> ·
  <a href="#contributing">Contributing</a> ·
  <a href="#roadmap">Roadmap</a>
</p>

---

## Overview

**Adhkar** is a free and open-source Islamic mobile application built with Flutter.

The project brings essential Islamic utilities together in one clean experience, including prayer timings, daily adhkar, Qibla direction, Hijri dates, reminders, and other tools for everyday worship.

The core philosophy is simple:

> **Technology should support worship, not distract from it.**

Adhkar aims to provide a calm, privacy-conscious, accessible, and reliable experience for Muslims around the world.

---

## Features

### Prayer Timings

Get daily prayer timings based on your location and selected calculation preferences.

- Fajr
- Sunrise
- Dhuhr
- Asr
- Maghrib
- Isha
- Location-based calculations
- Calculation method selection
- Madhab-specific Asr calculation
- Prayer notifications

### Daily Adhkar

Access commonly used remembrance and supplications throughout the day.

- Morning adhkar
- Evening adhkar
- After-Salah adhkar
- Before-sleep adhkar
- After-waking adhkar
- General dhikr
- Arabic text
- Transliteration
- Translation
- Repetition counts
- References where available

### Tasbeeh Counter

A focused digital counter for dhikr.

- Tap-to-count
- Target repetitions
- Progress tracking
- Reset functionality
- Simple, distraction-free interface

### Qibla

Find the direction of the Kaaba from your current location.

- Location-based Qibla calculation
- Compass interface
- Device orientation support
- Clear directional guidance

### Hijri Calendar

View Islamic dates alongside the Gregorian calendar.

- Current Hijri date
- Gregorian date
- Islamic months
- Regional handling
- Important Islamic dates

> **Regional note:** Hijri dates may differ by one day depending on local moon-sighting practices and regional conventions.

### Reminders

Create personal reminders for worship and everyday activities.

- Custom title
- Optional description
- One-time reminders
- Daily reminders
- Scheduled notifications
- Custom alarm duration
- Background scheduling

### Quiet Hours

Create scheduled quiet periods to reduce distractions during Salah, study, meetings, or personal worship.

On supported Android devices, Quiet Hours can use system notification-policy controls when the required permission is granted.

### Notifications

Receive scheduled notifications for prayer times and personal reminders.

- Prayer notifications
- Custom reminders
- Background scheduling
- Notification controls

---

## Screenshots

Screenshots are intentionally organized by feature so that the repository provides a quick visual overview of the application.

### Home & Prayer

<p align="center">
  <img src="screenshots/home.png" width="220" alt="Adhkar Home Screen">
  <img src="screenshots/prayer-timings.png" width="220" alt="Prayer Timings">
</p>

### Daily Adhkar

<p align="center">
  <img src="screenshots/daily-adhkar.png" width="220" alt="Daily Adhkar">
  <img src="screenshots/adhkar-detail.png" width="220" alt="Adhkar Details">
</p>

### Tasbeeh & Qibla

<p align="center">
  <img src="screenshots/tasbeeh.png" width="220" alt="Tasbeeh Counter">
  <img src="screenshots/qibla.png" width="220" alt="Qibla">
</p>

### Hijri Calendar & Reminders

<p align="center">
  <img src="screenshots/hijri-calendar.png" width="220" alt="Hijri Calendar">
  <img src="screenshots/reminders.png" width="220" alt="Reminders">
</p>

> **Note:** Add the corresponding images to the `screenshots/` directory using the filenames above. If a screenshot is not available yet, remove that image reference until it is ready.

---

## Technology Stack

| Technology | Purpose |
| --- | --- |
| Flutter | Cross-platform mobile application |
| Dart | Application development |
| AlAdhan API | Prayer timings and Islamic calendar data |
| Local Storage | User preferences and local application data |
| Android Services | Background notifications and scheduled reminders |
| iOS Services | Notifications and platform-specific capabilities |

---

## Architecture

Adhkar follows a modular feature-oriented structure intended to keep the application maintainable and scalable.

```text
lib/
├── core/
│   ├── constants/
│   ├── services/
│   ├── themes/
│   └── utilities/
│
├── features/
│   ├── adhkar/
│   ├── hijri/
│   ├── prayer/
│   ├── qibla/
│   ├── reminders/
│   └── settings/
│
├── shared/
│   ├── components/
│   └── widgets/
│
└── main.dart
```

The architecture separates feature-specific logic from shared services, components, and application-wide configuration.

---

## Getting Started

### Prerequisites

Install the following before running the project:

- Flutter SDK
- Dart SDK
- Android Studio or Xcode
- Git
- Android device/emulator or iOS device/simulator

Verify your Flutter environment:

```bash
flutter doctor
```

### Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/adhkar.git
cd adhkar
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

To see available devices:

```bash
flutter devices
```

Then run on a specific device:

```bash
flutter run -d <device-id>
```

---

## Configuration

Some features require access to device capabilities or external services.

### Location Permission

Location may be required for:

- Prayer timings
- Qibla direction
- Location-based Islamic services

### Notification Permission

Notifications may be required for:

- Prayer alerts
- Adhkar reminders
- Scheduled reminders

### Sensor Access

Qibla functionality may use device orientation and compass sensors.

### Android Notification Policy Access

Quiet Hours may require Android Notification Policy Access on supported devices.

Users should only grant permissions required for features they choose to use.

---

## Development

Before submitting changes, run the standard Flutter checks.

### Format

```bash
dart format .
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

A good pull request should ideally pass formatting, analysis, and relevant tests before submission.

---

## Islamic Content Guidelines

Because Adhkar contains religious content, contributions involving Quranic verses, Hadith, duas, adhkar, or Islamic rulings should be handled carefully.

When contributing religious content:

1. Verify the original source.
2. Preserve the Arabic text accurately.
3. Avoid changing the intended meaning.
4. Include references whenever possible.
5. Clearly distinguish sourced material from editorial content.
6. Do not present personal interpretations as established religious rulings.

For questions requiring scholarly judgment, users should consult qualified Islamic scholars.

---

## Privacy

Adhkar follows a privacy-conscious approach.

The project aims to:

- Minimize unnecessary data collection.
- Store user preferences locally where practical.
- Request permissions only when required.
- Avoid unnecessary access to device data.
- Give users control over optional features.

For complete details, see:

```text
PRIVACY.md
```

---

## Localization

Adhkar is designed with international users in mind.

Planned and supported language expansion may include:

- English
- Arabic
- Urdu
- Hindi
- Additional community-supported translations

Translation contributions are welcome.

---

## Contributing

Contributions are welcome.

You can contribute through:

- Bug fixes
- New features
- UI/UX improvements
- Accessibility improvements
- Translations
- Documentation
- Testing
- Islamic content verification
- Feature suggestions

### Contribution Workflow

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Run formatting and analysis.
5. Add or update tests where appropriate.
6. Commit your changes.
7. Push the branch.
8. Open a Pull Request.

Example:

```bash
git checkout -b feature/my-feature

dart format .
flutter analyze
flutter test

git add .
git commit -m "feat: add my feature"
git push origin feature/my-feature
```

Then create a Pull Request from your branch.

---

## Reporting Issues

Before opening an issue, please search existing issues to avoid duplicates.

For bug reports, include:

```text
Device:
Operating System:
App Version:
Flutter Version:

Description:

Steps to Reproduce:

Expected Behavior:

Actual Behavior:

Screenshots or Logs:
```

Clear reproduction steps make it significantly easier to investigate and resolve problems.

---

## Feature Requests

Feature ideas are welcome.

When proposing a feature, please describe:

- What the feature does
- Why it would be useful
- Who would benefit from it
- How you expect it to work
- Any relevant screenshots or examples

---

## Roadmap

### Available

- [x] Prayer timings
- [x] Daily adhkar
- [x] Tasbeeh counter
- [x] Qibla
- [x] Hijri calendar
- [x] Prayer notifications
- [x] Custom reminders
- [x] Quiet Hours
- [x] Regional Hijri handling

### Planned

- [ ] Expanded Quran experience
- [ ] Quran audio
- [ ] Additional dua collections
- [ ] Improved accessibility
- [ ] More languages
- [ ] Offline-first improvements
- [ ] More regional calculation support
- [ ] Islamic knowledge section
- [ ] Advanced worship tracking

The roadmap may change as the project evolves and based on community feedback.

---

## Project Structure

```text
adhkar/
├── android/
├── ios/
├── lib/
├── screenshots/
├── test/
├── assets/
├── README.md
├── LICENSE
├── PRIVACY.md
└── pubspec.yaml
```

---

## License

This project is open source.

See the `LICENSE` file for the complete license terms.

```text
Copyright © 2026 Adhkar Contributors
```

---

## Support the Project

If you find Adhkar useful, there are several ways to support the project:

- Star the repository
- Report bugs
- Suggest features
- Contribute code
- Improve documentation
- Help with translations
- Share the project with others

Every contribution helps improve the project for the wider community.

---

## Acknowledgements

Adhkar would not be possible without the work of the open-source community and the developers of the libraries, services, and tools used by the project.

Special thanks to everyone who contributes code, reviews, translations, testing, documentation, and feedback.

---

## Disclaimer

Adhkar is a software project intended to provide useful Islamic tools and resources.

It is not a replacement for qualified Islamic scholarship. Religious rulings and matters requiring scholarly judgment should be referred to trusted and qualified scholars.

---

## Contact & Community

For questions, suggestions, collaboration, or contributions, please use the GitHub repository's Issues and Discussions sections.

---

<p align="center">
  <strong>Adhkar</strong>
  <br>
  <sub>Your Daily Spiritual Companion</sub>
  <br><br>
  Built with Flutter · Open Source · Free for Everyone
</p>

<p align="center">
  If Adhkar is useful to you, consider giving the repository a star.
</p>
