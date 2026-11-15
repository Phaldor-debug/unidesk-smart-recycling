# Ünidesk — Smart Recycling Bin

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?logo=espressif&logoColor=white)
![Riverpod](https://img.shields.io/badge/state-Riverpod-0553B1)

A three-compartment (plastic / paper / glass) recycling bin for university campuses,
paired with a mobile app that turns recycling into a game.

A student picks the waste type in the app and scans the QR code on the bin. The bin
opens **only** the matching compartment, counts each item with an infrared sensor and
credits points to the student. Points feed a monthly leaderboard and unlock badges.

> **Note:** The app was built for Turkish university students, so its user interface,
> code comments and some identifiers are in Turkish.

## Features

- **Guided deposit flow** — choose waste type → scan bin QR → lid opens automatically,
  closes after 5 seconds of inactivity
- **Live session screen** — item count updates in real time as the IR sensor fires
- **Points & history** — every deposit is credited exactly once (Firestore transaction)
- **Monthly leaderboard** — podium-style ranking by points earned this month; last
  month's winners are kept
- **13 badges** in five groups (milestones, waste-type mastery, streaks, ranking,
  special), each with bonus points and an unlock celebration
- **Local notifications** — at most two per month, no server required
- **Auth** — email/password sign-up, email verification, password reset, session restore
- **Rewards module** — reward catalog, one-time redemption codes and a canteen staff
  verification screen *(implemented, currently disabled behind a feature flag)*

## Architecture

```
┌──────────────┐   Firestore    ┌──────────────┐   Realtime DB   ┌──────────┐
│   Flutter    │◄──────────────►│   Firebase   │◄───────────────►│  ESP32   │
│  (Android)   │  users, points │              │  lid commands,  │ 3 servos │
│              │  sessions      │              │  item counter   │ 3 IR sns │
└──────────────┘                └──────────────┘                 └──────────┘
```

- **Cloud Firestore** — persistent records: users, points, sessions, leaderboard, rewards
- **Realtime Database** — live channel to the ESP32 (`/bin_commands/{binId}`).
  Chosen deliberately: RTDB's ESP32 library support is far more mature than Firestore's.

### Deposit flow

1. The user picks a waste type → a `sessions/{id}` document is created (`status: pending`)
2. A command for the bin is written to RTDB at the same time
3. The ESP32 sees the command → opens the matching servo → `status: lidOpen`
4. The IR sensor counts every item → `depositedCount` is updated
5. After a period of inactivity the lid closes → `status: completed`
6. The app credits the points to the user **once**, inside a Firestore transaction

### Project structure

Each feature follows Clean Architecture with three layers:

```
lib/
├── core/                 # theme, constants, error types, Firebase providers, notifications
├── shared/               # navigation shell and shared widgets
└── features/
    ├── auth/             # sign-up, sign-in, profile, email verification
    ├── wallet/           # points balance and history
    ├── recycling/        # QR scanning, waste selection, live session, ESP32 bridge
    ├── leaderboard/      # monthly ranking
    ├── badges/           # badge rules, stats tracking, celebrations
    └── rewards/          # reward catalog, redemption codes, staff verification
        ├── domain/       # business rules — knows nothing about Firebase
        ├── data/         # the only layer that talks to Firebase
        └── presentation/ # screens and Riverpod providers
```

`firmware/` contains the ESP32 Arduino/C++ code and a [Wokwi](https://wokwi.com)
simulation diagram, so the hardware side can be tried without a physical board.

## Tech stack

| Area | Technology |
|---|---|
| Mobile | Flutter, Riverpod |
| Backend | Firebase Auth, Cloud Firestore, Realtime Database |
| Hardware | ESP32, 3× servo motor, 3× IR obstacle sensor |
| Firmware | Arduino/C++, Firebase ESP Client |

## Security

The Firestore rules ([firestore.rules](firestore.rules)) are deny-by-default. Among
other things they:

- let users read and write only their own profile and sessions
- force new sessions to start from zero, and stop a claimed session from being reset
  to claim points again
- allow redemption codes to move only one way (`active → used`), with every other
  field locked
- make the reward catalog read-only from the client

## Getting started

Requires the Flutter SDK and your own Firebase project.

```bash
flutter pub get
flutterfire configure     # connect the app to your Firebase project (once)
flutter run
```

Then deploy the security rules with `firebase deploy --only firestore,database`.

Two development helpers make it possible to test without hardware. They appear
**only in debug builds**:

- a **hardware simulator** on the active session screen — open lid / count item / finish
- a **test QR code** on the home screen — try scanning without a printed label

For the firmware, see [firmware/README.md](firmware/README.md).

## Known limitations

- Point and counter updates are made from the client; there is no server-side
  validation (Cloud Functions) yet. The rules block access to other users' data and
  the reuse of one-time codes, but they cannot fully stop a user from tampering with
  their own data.
- The canteen verification screen lives inside the same app; a separate staff role
  is planned.
- The bin's QR code is static; a dynamic, periodically changing QR code on a
  bin-mounted display is planned.
