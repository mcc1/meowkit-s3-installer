# meowkit-s3-installer

Official web installer for MeowKit-S3 firmware.

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
