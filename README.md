# meowkit-s3-installer

Public personal web-installer mirror for MeowKit-S3 firmware. This is not an
official vendor release. The original upstream remote is kept as `origin`; the
personal GitHub mirror is `mcc1/meowkit-s3-installer`.

## Personal modifications

This mirror adds and documents the following local changes:

- A separate local-test installer button and manifest for firmware built from
  the personal firmware repository.
- A generated factory image plus `SHA256SUMS.txt` for local reproducibility.
- `tools/start-local-installer.ps1`, which serves the installer over localhost
  so desktop Chrome or Edge can use the Web Serial flow.
- Version labels that distinguish experimental local-test firmware from the
  vendor's stable factory image.

These files are shared for inspection and reproducibility by other MeowKit
owners. The local-test image is experimental and is not an official vendor
release; verify the source, checksum, and device target before installation.

## Start the local installer

The installer must be served over a local web server; opening `index.html`
directly as a `file://` URL will not load the manifest correctly. From this
repository, run:

```powershell
.\tools\start-local-installer.ps1
```

The tool starts a local server at `http://localhost:8000/`, opens the default
browser, and keeps the server alive until you press `Ctrl+C`. Use desktop
Chrome or Edge, connect MeowKit with a USB data cable, and choose either the
stable installer or the local-test installer button.

To use another port or open the page yourself:

```powershell
.\tools\start-local-installer.ps1 -Port 8080 -NoBrowser
```

## Firmware artifacts

The firmware repository's `tools/publish-firmware.ps1` prepares the merged
factory image, manifest, and `SHA256SUMS.txt` for either `stable` or
`local-test`. It does not flash the device or publish to a hosting service.

## Verification status (2026-09-05)

- `start-local-installer.ps1 -Port 18765 -NoBrowser` served `index.html`
  successfully over HTTP (`200`, 5030 bytes), and the test port was released
  after the test server was stopped.
- The current local-test manifest points to the factory image at flash offset
  `0`, and its `SHA256SUMS.txt` matches the generated image:
  `a402738fbfd0621c1fc6e40943ea3917be1c302a5188f435729f51f18e298945`.
- Browser Web Serial connection and actual device flashing are still pending
  physical/browser verification.
