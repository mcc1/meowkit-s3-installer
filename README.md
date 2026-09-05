# meowkit-s3-installer

Public personal web-installer mirror for MeowKit-S3 firmware. This is not an
official vendor release. The original upstream remote is kept as `origin`; the
personal GitHub mirror is `mcc1/meowkit-s3-installer`.

## Personal modifications

This mirror adds and documents the following local changes:

- A separate local-test installer button whose version and readiness state come
  from generated metadata and a manifest.
- A generated factory image, metadata, manifest, and `SHA256SUMS.txt` for
  local reproducibility.
- `tools/start-local-installer.ps1`, which serves the installer over localhost
  so desktop Chrome or Edge can use the Web Serial flow.
- A static `index.html` shell that can be packaged unchanged for GitHub Pages.

The generated files are intentionally not tracked in Git. Recreate them from
the firmware source with the publish tool before local testing or CI packaging.
The local-test image is experimental and is not an official vendor release;
verify the source, checksum, and device target before installation.

## Start the local installer

The installer must be served over a local web server; opening `index.html`
directly as a `file://` URL will not load the manifest correctly. From this
repository, run:

```powershell
.\tools\start-local-installer.ps1
```

The tool validates the requested generated channel first, then starts a local
server at `http://localhost:8000/`, opens the default browser, and keeps the
server alive until you press `Ctrl+C`. Use desktop Chrome or Edge, connect
MeowKit with a USB data cable, and choose either the stable installer or the
local-test installer button.

To use another port or open the page yourself:

```powershell
.\tools\start-local-installer.ps1 -Port 8080 -NoBrowser
```

## "Failed to download manifest" right after flashing

ESP Web Tools re-downloads `manifest.json` after the write phase finishes
(`_initialize(true)` in its install dialog). If that fetch fails the dialog
shows "Failed to download manifest" even though the firmware is already fully
written — do not re-flash, just reboot the device.

The fetch failed because Python's `http.server` speaks HTTP/1.0 by default
(one TCP connection per request) and on Windows a noticeable share of those
connections are reset: measured 3 of 40 fetches on a fresh server and 13 of
40 on one that had run for hours. `start-local-installer.ps1` therefore starts
the server with `--protocol HTTP/1.1` (Python 3.11+), which measured 0 failures
in 200 sequential and 15 concurrent fetches. Restart the server after pulling
this change; a server started before it keeps the old behaviour.

Publishing a new local-test build while a browser is mid-flash also produces
this error (the channel directory is briefly missing); use
`meowkit-s3-firmware/tools/publish-local-test.ps1`, which stages the build and
swaps directories atomically.

## After installing: leaving download mode

MeowKit has no reset button. When the running firmware is asked to enter the
bootloader (ESP Web Tools toggles DTR/RTS on the USB CDC port), the Arduino
core sets the `RTC_CNTL_FORCE_DOWNLOAD_BOOT` flag and reboots into the ROM
download mode over USB-Serial/JTAG. That flag survives the RTS-emulated reset
that ESP Web Tools issues after flashing, so the board comes back up in the
bootloader again (blank screen, `USB JTAG/serial debug unit` still present).
This is arduino-esp32 issue #6762; esptool.py clears the flag before its hard
reset, esptool-js does not.

The page therefore has a **Reboot device** button below the channel cards. It
opens the same serial port, clears the flag with a ROM `WRITE_REG`, and pulses
RTS. If it cannot reach the bootloader (the board is already running firmware,
or another tab holds the port), it says so and does nothing else. Fallback:
hold the power button until MeowKit switches off, then switch it on.

The stable card shows `generated/stable/metadata.json returned HTTP 404` on a
local machine because only the `local-test` channel is generated here; that is
expected, not a fault of the page.

## Generated site contract

The firmware repository's `tools/publish-firmware.ps1` prepares the merged
factory image, `metadata.json`, manifest, and `SHA256SUMS.txt` under
`generated/<channel>/` for either `stable` or `local-test`. It does not flash
the device, modify `index.html`, or publish to a hosting service.

Validate the generated output:

```powershell
.\tools\validate-site.ps1 -Channel local-test
```

Prepare a deployment directory with the same layout that local HTTP serving
and GitHub Pages will use:

```powershell
.\tools\prepare-site.ps1 -Channel local-test -SiteRoot .\site -Clean
```

`generated/` and `site/` are build outputs and are intentionally ignored by
Git. The tracked `index.html` loads each channel's `metadata.json`, verifies
the metadata/manifest version match and the factory image availability, and
keeps the install button disabled when validation fails.

`.github/workflows/pages.yml` is a manual Pages workflow that runs the same
firmware packaging and `prepare-site.ps1` steps, uploads `site/` with
`actions/upload-pages-artifact`, and deploys it with `actions/deploy-pages`.
It is intentionally manual until the firmware channel/version policy is
stable. The Pages bundle therefore uses the same generated-site contract as
this local server.

## Verification status (2026-09-05)

- `start-local-installer.ps1 -Port 18765 -NoBrowser` served `index.html`
  successfully over HTTP (`200`, 5030 bytes), and the test port was released
  after the test server was stopped.
- The current local-test generated metadata points to a factory image at flash
  offset `0`; `tools/validate-site.ps1` checks its manifest version, checksum,
  and artifact path before the local server starts.
- Browser Web Serial connection and actual device flashing are still pending
  physical/browser verification.
