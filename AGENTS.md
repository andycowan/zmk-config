# AGENTS.md

Guidance for AI/coding agents working in this ZMK firmware config repository.

## Project overview

- This repo is a ZMK user config for Andrew's split Corne keyboard.
- Target hardware in `build.yaml`:
  - `nice_nano_v2` + `corne_left nice_view_adapter nice_view`
  - `nice_nano_v2` + `corne_right nice_view_adapter nice_view`
- ZMK version is pinned to `v0.3` in both:
  - `.github/workflows/build.yml` (`zmkfirmware/zmk/.github/workflows/build-user-config.yml@v0.3`)
  - `config/west.yml` (`manifest.defaults.revision: v0.3`)
- Documentation: <https://zmk.dev/docs>

## Repository map

- `build.yaml` — GitHub Actions build matrix. Edit this when adding/removing board + shield builds.
- `config/corne.keymap` — shared keymap for both Corne halves. Because this file is named `corne.keymap`, it applies to both `corne_left` and `corne_right`.
- `config/corne.conf` — shared Kconfig for both halves. Currently enables ZMK display support for nice!view.
- `config/west.yml` — ZMK/Zephyr west manifest for local builds.
- `zephyr/module.yml` — makes this config repo usable as a Zephyr module with `board_root: .`.
- `.github/workflows/build.yml` — delegates firmware builds to the upstream ZMK user-config workflow.
- `.zmk/` — local ZMK/west checkout/cache; ignored by git. Do not commit or rely on generated files here.

## Current keymap notes

- Layers are defined in order, so their numeric IDs are:
  - `default_layer` = layer `0`
  - `lower_layer` = layer `1`
  - `raise_layer` = layer `2`
- Base thumb keys use `&mo 1` and `&mo 2`; keep these aligned if layers are reordered.
- Lower layer includes Bluetooth controls (`BT_CLR`, `BT_SEL 0` through `BT_SEL 4`) and media controls.
- `config/corne.conf` enables `CONFIG_ZMK_DISPLAY=y`; RGB underglow settings are present but commented out.

## Editing rules

- Keep changes surgical. For normal layout changes, only edit `config/corne.keymap`.
- Maintain the exact number of bindings per layer for the Corne layout. A missing or extra binding will break the build.
- Keep keymap comments in sync with bindings when changing visible layout behavior.
- Prefer named layer constants only if you update all `&mo <n>`, `&to <n>`, or related references consistently.
- Do not edit upstream ZMK files under `.zmk/zmk/`; change local config files or pin/update `config/west.yml` instead.
- Do not commit generated firmware, build directories, or `.zmk/` contents.

## Build and verification

Primary verification is the GitHub Actions build triggered by pushing changes. For local validation, use the ZMK/west toolchain only if it is installed and the workspace is initialized.

From the repo root:

```sh
# Initialize/update the local ZMK west workspace if needed.
zmk west update

# Build left half into an isolated output directory.
REPO="$PWD"
cd "$REPO/.zmk/zmk/app"
west build -p -d "$REPO/build/left" -b nice_nano_v2 -- \
  -DSHIELD="corne_left nice_view_adapter nice_view" \
  -DZMK_CONFIG="$REPO/config"

# Build right half into a separate output directory.
west build -p -d "$REPO/build/right" -b nice_nano_v2 -- \
  -DSHIELD="corne_right nice_view_adapter nice_view" \
  -DZMK_CONFIG="$REPO/config"
```

Notes:

- If adding custom boards/shields under this repo, also pass `-DZMK_EXTRA_MODULES="$REPO"` for local builds.
- Split keyboard halves should be built into separate directories so the `zmk.uf2` output for one side does not overwrite the other.
- Use pristine builds (`-p`) when changing board/shield combinations or debugging stale CMake/devicetree output.
- Firmware artifacts are written under `build/left/zephyr/` and `build/right/zephyr/` when building locally.

## Flashing safety

- Flash the left and right halves with the matching firmware artifacts.
- For UF2-capable nice!nano boards, enter bootloader mode and copy the correct `.uf2` file to the mounted drive.
- Test over USB first, especially after layout or Bluetooth changes.
- For split BLE pairing issues after flashing, reset both halves together and consult ZMK split keyboard troubleshooting before making speculative config changes.

## Common tasks

- Change a key: edit the corresponding binding in `config/corne.keymap`, update the layer comment, then build both halves.
- Add a ZMK feature: add/modify `CONFIG_*` entries in `config/corne.conf`, then build both halves.
- Add another hardware target: update `build.yaml`; keep `config/west.yml` and workflow ZMK versions aligned unless intentionally upgrading.
- Upgrade ZMK: update both the workflow ref and `config/west.yml` revision together, then run a clean/pristine build and verify generated firmware for both halves.
