# Natural Scrolling Switcher

[한국어](README.ko.md)

Natural Scrolling Switcher (NSS) is a lightweight macOS menu bar utility that automatically manages the system-wide **Natural Scrolling** setting based on the pointing devices connected to your Mac.

It is designed for users who prefer:

- **Natural Scrolling** with a trackpad
- **Classic scrolling** with an external mouse

NSS automatically handles the change, so you do not need to open System Settings and switch the scroll direction every time you connect or disconnect a mouse.

---

## Features

- Automatically detects connected external mice
- Automatically switches the macOS **Natural Scrolling** setting
- Event-driven device detection
- Per-mouse Auto / Manual mode
- Per-mouse scroll direction setting
- Restores saved settings when a mouse reconnects
- Supports multiple external mice
- Optional display of internal devices such as the built-in trackpad
- Launch at login support
- English and Korean interface
- Runs conveniently from the macOS menu bar

---

## How It Works

macOS uses a single system-wide scroll direction setting for all mice and trackpads, collectively referred to here as pointing devices.

NSS detects connected pointing devices and automatically changes that global setting according to the configured device behavior.

For a typical setup using a built-in trackpad and an external mouse:

| Situation | Scroll Direction |
| --- | --- |
| Trackpad only | Natural Scrolling |
| External mouse connected | Classic scrolling |
| External mouse disconnected | Natural Scrolling |

This means you can switch between a trackpad and a conventional mouse without manually changing the macOS scroll direction each time.

---

## Device Settings

Select **Devices...** from the NSS menu to manage connected pointing devices.

Each external mouse can be configured in one of two modes: **Auto** or **Manual**.

### Auto

In Auto mode, the device follows NSS's automatic switching behavior.

For a typical external mouse, NSS switches macOS to Classic scrolling while the mouse is connected and restores Natural Scrolling when the mouse is disconnected.

### Manual

Manual mode lets you explicitly choose the scroll direction associated with that device.

When Manual mode is selected, use **Manual Direction** to choose the desired scroll direction.

---

## When Multiple Devices Are Connected

When multiple mice are connected, NSS determines which device setting takes priority using the following order:

1. The connected mouse whose setting was edited most recently
2. Otherwise, the most recently connected mouse

When that mouse is disconnected, the last connected remaining mouse takes over.

Because macOS uses only one global scroll direction setting for all pointing devices, two simultaneously connected devices cannot use different system scroll directions at the same time.

---

## Device Recognition

NSS remembers supported pointing devices and attempts to restore their saved settings when they reconnect.

When possible, NSS uses relatively stable identifiers such as serial numbers or unique device IDs to recognize previously connected devices.

Some devices provide limited identification information. In those cases, identical devices may not always be distinguishable from one another.

---

## Menu Bar

The NSS menu provides access to:

- **About NSS**
- **Launch at login**
- **NSS Control**
  - Enabled
  - Disabled
- **Language**
  - System Default
  - English
  - 한국어
- **Devices...**
- **Quit Natural Scrolling Switcher**

### NSS Control

Selecting **Disabled** temporarily stops NSS from automatically managing the scroll direction without quitting the app.

Select **Enabled** at any time to resume automatic control.

---

## Language

NSS supports the following language options:

- System Default
- English
- 한국어

When **System Default** is selected, NSS follows the current macOS language setting.

---

## Show Internal Devices

By default, the Devices window focuses on external pointing devices such as mice.

Enable **Show internal devices** if you also want internal pointing devices, such as the built-in trackpad, to appear in the device list.

---

## Installation

1. Download the latest version from the GitHub Releases page.
2. Extract the downloaded ZIP file.
3. Move **Natural Scrolling Switcher.app** to the `/Applications` folder.
4. Launch the app.

NSS runs from the macOS menu bar.

---

## System Requirements

- macOS 13.5 or later
- Mac

---

## Launch at Login

Enable **Launch at login** from the NSS menu to start Natural Scrolling Switcher automatically whenever you log in to macOS.

---

## Privacy

Natural Scrolling Switcher does not collect, store, or transmit personal data.

The app does not require an online account and does not use analytics or telemetry.

---

## Technical Notes

macOS does not provide separate system-level scroll direction settings for individual pointing devices.

NSS works around this limitation by dynamically changing the global Natural Scrolling setting according to the currently applicable device configuration.

Device detection is event-driven rather than based on periodic polling.

---

## License

See the repository's license file for details.

---

## macOS Security Notice

Natural Scrolling Switcher is currently not signed with an Apple Developer ID or notarized by Apple.

As a result, macOS may display a security warning and prevent the app from opening the first time you launch it.

If this happens:

1. Open **System Settings → Privacy & Security**.
2. Find the message indicating that Natural Scrolling Switcher was blocked and click **Open Anyway**.
3. In the confirmation dialog, click **Open** again.

Natural Scrolling Switcher does not collect, store, or transmit personal data to external servers.
