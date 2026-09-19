# Device identity checks

From the repository root, run:

```sh
swiftc -module-cache-path /tmp/nss-identity-module-cache \
  NaturalScrollingSwitcher/PointingDevice.swift \
  NaturalScrollingSwitcher/MouseDetector.swift \
  Tests/DeviceIdentityTests.swift -o /tmp/nss-device-identity-tests
/tmp/nss-device-identity-tests
```

The deterministic checks cover identical models/serials, missing identifiers,
reconnect hints, duplicate additions/removals, multiple mice, and the existing
internal-device exclusion. A read-only HID check verifies initial enumeration,
matching callback deduplication, and stop/restart against currently connected
devices. Keep devices connected during the short snapshot check. It does not
open HID devices, request input permission, or change scroll settings.

Physical USB/Bluetooth hot-plug still needs a manual test: connect two mice,
with both device modes set to Auto, remove one (scrolling stays OFF), then
remove the last (scrolling becomes ON). Devices
exposed by a receiver are HID endpoints; a receiver may not expose each paired
physical mouse separately.


# Device policy checks

```sh
swiftc -module-cache-path /tmp/nss-policy-tests-cache \
  NaturalScrollingSwitcher/PointingDevice.swift \
  NaturalScrollingSwitcher/KnownDevice.swift \
  NaturalScrollingSwitcher/LanguageSettings.swift \
  NaturalScrollingSwitcher/L10n.swift \
  NaturalScrollingSwitcher/DevicePolicy.swift \
  NaturalScrollingSwitcher/DevicePolicyStore.swift \
  Tests/DevicePolicyTests.swift -o /tmp/nss-device-policy-tests
/tmp/nss-device-policy-tests
/tmp/nss-device-policy-tests write NSS.PolicyRestartTest
/tmp/nss-device-policy-tests read NSS.PolicyRestartTest
```

The last two commands verify medium-confidence fingerprint persistence across
separate processes with changed registry and location IDs. Tests use isolated
UserDefaults suites and do not alter application preferences or scrolling.
Checks cover Manual/Classic selection, an offline retained row, reconnection restoring
Manual/Classic, collision quarantine, session-only records, Forget Device, v1/v2 to v3 migration,
metadata mismatch, and invalid archives.

In the app, open **Devices…** to inspect saved devices and new connected candidates.
Selecting a policy saves a KnownDevice. Disconnected saved devices remain visible
and offer **Forget Device**. Internal devices are hidden until **Show internal
devices** is enabled. Mode is Auto or Manual; Manual Direction is enabled only in
Manual mode. Old Follow Auto and Ignore migrate to Auto; Natural and Classic
migrate to Manual with their respective direction. Auto retains the last manual
direction for later use.

A connected external mouse's policy edit applies immediately and becomes the
preferred device until it disconnects or another connected mouse's policy is
edited. Otherwise the latest connection wins. An initial batch of devices has no
observed arrival order, so registry ID (then session UUID) breaks ties deterministically.
Selecting device Auto follows the aggregate rule: any external mouse means Classic;
no external mouse means Natural. Device Mode uses a segmented Auto/Manual control.

Global control is Enabled or Disabled, stored as `scrollControlEnabled` in
UserDefaults. Disabled performs no scroll writes, including on connection changes
or device-policy edits. It disables Devices… and closes an already-open Devices
window. Device detection, saved records and priority tracking continue. Enabling
immediately evaluates the current policy, even if its direction matches the value
last applied before disabling. At startup, application waits for initial device
enumeration and only applies while Enabled. Legacy global `automatic` (or missing)
migrates to Enabled; legacy `on`/`off` migrates to Disabled to preserve the current
system direction. The old global key is removed; device policy data is untouched.
Offline edits only save policy. Ambiguous identities cannot restore saved Manual
policies.

Serial/UniqueID identities have high confidence. A complete combination of
transport, VID, PID, manufacturer and product name has medium confidence; it can
match a reconnected device but cannot distinguish identical models used one at a
time. Simultaneous collisions are quarantined persistently. Incomplete identities
remain session-only: their saved record stays visible but cannot be automatically
reconnected. Registry and location IDs are never persisted as fingerprints.


# Scroll application checks

```sh
swiftc -module-cache-path /tmp/nss-apply-tests-cache \
  NaturalScrollingSwitcher/PointingDevice.swift \
  NaturalScrollingSwitcher/KnownDevice.swift \
  NaturalScrollingSwitcher/LanguageSettings.swift \
  NaturalScrollingSwitcher/L10n.swift \
  NaturalScrollingSwitcher/DevicePolicy.swift \
  NaturalScrollingSwitcher/DevicePolicyStore.swift \
  NaturalScrollingSwitcher/DevicePolicyPriority.swift \
  NaturalScrollingSwitcher/MouseDetector.swift \
  NaturalScrollingSwitcher/ScrollManager.swift \
  NaturalScrollingSwitcher/ScrollMonitor.swift \
  Tests/ScrollPolicyTests.swift -o /tmp/nss-scroll-policy-tests
/tmp/nss-scroll-policy-tests
/tmp/nss-scroll-policy-tests write-disabled NSS.ControlRestartTest
/tmp/nss-scroll-policy-tests read-disabled NSS.ControlRestartTest
/tmp/nss-scroll-policy-tests write-enabled NSS.ControlRestartTest
/tmp/nss-scroll-policy-tests read-enabled NSS.ControlRestartTest
```

The default run records application calls without changing system settings. It
checks immediate direction changes, control enable/disable, priority, disconnect fallback,
offline edits, reconnection, ambiguous identities, internal-device exclusion,
deduplication, initial enumeration, global-state migration/restoration, and stop behavior. Optional `--system` uses the real ScrollManager,
reads the macOS preference after changes, and restores the starting direction on
normal completion. It temporarily changes the system scroll direction.

Physical USB/Bluetooth hot-plug and perceived wheel/trackpad direction should
still be tested in the running app. No polling, HID open, or input-access request
is introduced by these paths.


# Window / Dock lifecycle checks

```sh
swiftc -module-cache-path /tmp/nss-window-tests-cache \
  NaturalScrollingSwitcher/AppWindowCoordinator.swift \
  NaturalScrollingSwitcher/PointingDevice.swift \
  NaturalScrollingSwitcher/MouseDetector.swift \
  Tests/AppWindowCoordinatorTests.swift -o /tmp/nss-window-tests
/tmp/nss-window-tests
```

This GUI integration test opens real Cocoa windows and changes only its own
activation policy. It checks accessory startup, individual windows, both close
orders, the last-window transition, minimizing/reopening, instance/delegate reuse,
and retention of a menu bar item and HID detector. It does not change scroll
settings. Run in a logged-in macOS GUI session without changing connected devices.
The test has been compiled; its GUI execution was not authorized in this session.

Manual verification in the actual app: open Devices and About together, close
one and confirm the Dock icon remains, then close the last and confirm the app
leaves the Dock while its menu bar item remains. Repeat in the opposite order.
Disabling NSS control with both windows open must close Devices but keep About
and the Dock icon. Quit should still terminate the app normally.

# Localization and language selection

English is the development language; `Localizable.xcstrings` contains explicit
English and Korean values under semantic keys. `L10n` resolves the process's
language before `AppDelegate` constructs any UI or device store. It uses explicit
localized bundles for String-valued SwiftUI labels, accessibility, errors, and
AppKit window titles. The SwiftUI locale is set to the same language. HID metadata,
classification literals, logs, preference keys, and policy archives are unchanged.

`appLanguagePreference` stores `systemDefault`, `english`, or `korean`; absence
means system default. Foundation matches the system preference list against en/ko,
including regional variants. If neither language matches, English is the fallback.
The app never writes `AppleLanguages` or changes the system's preferred languages.

Changing preference without changing the effective language saves immediately.
An actual language change requires confirmation in the current process language.
Cancel writes nothing. Restart synchronizes the preference, starts a separate
helper instance, then terminates through the normal application lifecycle. The
helper skips SwiftUI/AppDelegate/HID initialization, waits for process exit using
DispatchSource, and invokes `/usr/bin/open -n` on the app bundle. Failed helper
preparation rolls back the preference and leaves the app open. A 30-second wait
limit prevents an abandoned helper if termination is cancelled.

Translations come verbatim from `NSS_Translate.xlsx` (44 rows). Additional strings
are from the localization request (system language label, language names, restart
confirmation and buttons) or explicitly approved in the conversation:
`Language` → `언어(Language)` and the restart failure message →
`Natural Scrolling Switcher를 다시 시작할 수 없어 언어 설정이 변경되지 않았습니다.`
Named worksheet placeholders map to positional String Catalog placeholders;
no sentence is assembled from translated fragments.

Build the app first, then run the pure model/catalog checks:

```sh
swiftc -module-cache-path /tmp/nss-localization-tests-cache \
  NaturalScrollingSwitcher/LanguageSettings.swift \
  NaturalScrollingSwitcher/L10n.swift \
  NaturalScrollingSwitcher/AppRelauncher.swift \
  Tests/LocalizationTests.swift -o /tmp/nss-localization-tests
/tmp/nss-localization-tests \
  /tmp/NSS-localization-build/Build/Products/Debug/NaturalScrollingSwitcher.app \
  NaturalScrollingSwitcher/Localizable.xcstrings
python3 Tests/verify_translation_table.py \
  /Users/user/Desktop/NSS_Translate.xlsx NaturalScrollingSwitcher/Localizable.xcstrings
```

The Python audit requires openpyxl. No Python dependency is added to the app.
These checks passed: supported/unsupported system languages, regional matching,
forced languages, same-language save, cancel with no mutation, restart preparation,
rollback, persistence, every compiled translation, all interpolated entries, and
process-exit waiting (including an already-exited process and timeout). UserDefaults
checks require an environment allowing writes to isolated test preference domains.

`LocalizationRuntimeTests.swift` was compiled into a separate headless test bundle
with the app's en/ko resources. Separate-process runs passed for en/ko/unsupported
system preferences and both forced-language directions, including enum titles,
window title strings, accessibility, and error text. `RelaunchSmokeTests.swift` was
compiled into another headless test bundle using the production relaunch helper;
it confirmed LaunchServices relaunched that bundle after the original PID exited.
Neither test runs NSS's HID detector or modifies real NSS preferences/scrolling.

For a repeatable bundled-runtime or LaunchServices check, create a temporary .app
with a unique CFBundleIdentifier, CFBundleExecutable matching the test binary,
and the built en.lproj/ko.lproj resources under Contents/Resources. Compile the
runtime test with LanguageSettings, L10n, and DevicePolicy. Run `clear`, then
`check-en -AppleLanguages '(en-US)'`, `check-ko -AppleLanguages '(ko-KR)'`,
`check-en -AppleLanguages '(fr-FR,ja-JP,de-DE)'`, `save-ko`,
`check-ko -AppleLanguages '(en-US)'`, `save-en`, `check-en -AppleLanguages '(ko-KR)'`,
and finally `clear`. For the relaunch smoke test compile AppRelauncher and
RelaunchSmokeTests into a second temporary .app (LSUIElement=true), run its binary
with `--start`, and inspect the adjacent `.marker` file for PASS.

Actual UI checks still needed in Xcode/the installed app: menu checkmarks and
Korean layout; Cancel and Restart via the real dialog in both directions; Devices
and About together and both close orders; VoiceOver labels; physical Bluetooth/USB
hot-plug and scroll direction. These are separate from the automated model,
resource, and headless relaunch checks. Debug and Release macOS builds passed with
code signing disabled. The previous window/Dock GUI test remains unexecuted.
