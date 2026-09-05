# MeowKit-S3 installer agent instructions

This public repository is a personal derivative of the vendor installer. It is
not an official release. Keep the upstream GitHub repository as `origin` and
use the personal public mirror `mcc1/meowkit-s3-installer` as the `github`
remote when it is configured locally.

## Personal modifications

- `local-test/manifest.json` and the local-test button in `index.html` expose
  firmware built from the personal firmware repository.
- `firmware/local-test/` contains the generated factory image and its
  `SHA256SUMS.txt`; these are experimental artifacts, not vendor releases.
- `tools/start-local-installer.ps1` serves this repository over localhost for
  desktop Chrome or Edge Web Serial testing.
- Stable and local-test artifacts must remain visibly distinct in filenames,
  manifests, and page labels.

## Change and verification rules

- Check this repository's Git status before editing and preserve unrelated
  changes.
- Update `manifest.json`, the page label, and `SHA256SUMS.txt` together. Prefer
  `meowkit-s3-firmware/tools/publish-firmware.ps1` for generated artifacts.
- Run `git diff --check` and verify the checksum against the actual binary after
  artifact changes.
- Do not claim browser Web Serial or device flashing is verified without a
  physical/browser test. Factory installation may erase device settings.
- Keep upstream provenance and personal modifications clear to other MeowKit
  owners. Never commit credentials, Wi-Fi passwords, or private device data.
