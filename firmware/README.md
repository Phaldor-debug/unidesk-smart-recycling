# Ünidesk ESP32 Firmware

This firmware was written to be tested on **Wokwi** (a browser-based ESP32 simulator)
before the physical hardware arrived. It talks to the real Firebase backend, so a flow
tested here behaves exactly the same on the real board.

## Configuration

At the top of [`unidesk_bin/unidesk_bin.ino`](unidesk_bin/unidesk_bin.ino):

| Define | Purpose |
|---|---|
| `WIFI_SSID` / `WIFI_PASSWORD` | Wi-Fi network (`Wokwi-GUEST` with an empty password in the simulator) |
| `API_KEY` | Your Firebase project's Web API key |
| `DATABASE_URL` | Your Realtime Database URL |
| `BIN_ID` | Which bin this board is (`demo-bin-01`) |

## Testing in Wokwi (no installation, runs in the browser)

1. Sign in at [wokwi.com](https://wokwi.com)
2. Choose **New Project → ESP32**
3. Replace the contents of the `sketch.ino` tab with **`unidesk_bin.ino`**
4. Replace the contents of the `diagram.json` tab with this folder's **`diagram.json`**
5. Open **Library Manager** and add:
   - `Firebase ESP Client` (by mobizt)
   - `ESP32Servo`
6. Press the green **▶ Start Simulation** button

## What you should see

1. The **Serial Monitor** reports the Wi-Fi and Firebase connections
2. In the Flutter app, start a session with **plastic** as the waste type
3. Within a few seconds the Serial Monitor logs the new session and the
   **plastic servo rotates**
4. Click the **plastic IR** button in Wokwi a few times — each click is one detected item
5. The counter on the app's active session screen **updates in real time**
6. After ~5 seconds without a click the servo closes, the session becomes
   `completed` and the app credits the points

## Pin map (same on the real hardware)

| Part | ESP32 pin |
|---|---|
| Servo — plastic | GPIO 13 |
| Servo — paper | GPIO 12 |
| Servo — glass | GPIO 14 |
| IR sensor — plastic | GPIO 27 |
| IR sensor — paper | GPIO 26 |
| IR sensor — glass | GPIO 25 |

### Why buttons instead of IR sensors?

Wokwi has no IR obstacle sensor part. From the software's point of view a push button
and an IR sensor behave identically — both pull a pin LOW/HIGH — so the code needs no
change on the real hardware; the button is simply replaced by the sensor.

## Flashing a real board

1. Install the [Arduino IDE](https://www.arduino.cc/en/software)
2. **File → Preferences** → add to "Additional Boards Manager URLs":
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. **Tools → Board → Boards Manager** → search for `esp32` and install it
4. **Tools → Manage Libraries** → install `Firebase ESP Client` (mobizt) and `ESP32Servo`
5. Open `unidesk_bin.ino` and set the values from [Configuration](#configuration)
6. Connect the ESP32 over USB, select the port and press **Upload**

## Known limitations

- Only a single bin (`BIN_ID`) is supported; multiple bins would only require reading
  the ID from per-device configuration instead of a constant.
- The board uses anonymous Firebase Auth with no device identity. That is fine for a
  prototype; production would need per-device credentials.
