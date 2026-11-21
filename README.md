# Hex Picker

A tiny macOS app that shows the hex code of whatever is under your cursor.

- A tooltip follows the cursor with a colour swatch and the hex code (sRGB).
- The ◉ menu bar icon has **Copy Hex** and **Quit**.

## Build

Needs Xcode command line tools and macOS 14 or later.

```bash
./build.sh
```

This outputs `build/HexPicker.dmg`. Open it and drag **Hex Picker** into **Applications**.

## First launch

- **Screen Recording:** macOS asks for this permission so the app can read pixel colours. Allow it in System Settings → Privacy & Security → Screen & System Audio Recording, then reopen the app.
- **Gatekeeper:** the app is ad-hoc signed, not notarised. If macOS blocks it, right-click the app and choose **Open**.

Each rebuild changes the signature, so macOS asks for Screen Recording permission again.
