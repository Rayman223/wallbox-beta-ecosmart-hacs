# Wallbox Beta EcoSmart — HACS distribution

Test/beta build of the `wallbox_beta_ecosmart` Home Assistant integration. This is a fork of the official `wallbox` integration extended with EcoSmart mode handling (resume button, mode selection, etc.).

> ⚠️ **Not for production.** This is a development build maintained for testing before the changes are submitted upstream to Home Assistant Core. Do not run it next to the official `wallbox` integration without understanding that both will poll the Wallbox API independently.

## Installation via HACS

1. In Home Assistant, open **HACS**.
2. Click the **⋮** menu (top-right) → **Custom repositories**.
3. Add this repository URL: `https://github.com/Rayman223/wallbox-beta-ecosmart-hacs`
4. Category: **Integration** → **Add**.
5. The repository now appears in HACS. Open it and click **Download**.
6. **Restart Home Assistant** (*Settings → System → Restart*).
7. *Settings → Devices & Services → + Add Integration* → search **Wallbox_beta_ecosmart** → follow the config flow.

## Updating

When a new sync is pushed, HACS will show an update for "Wallbox Beta EcoSmart". Click **Redownload**, then restart Home Assistant.

## Source of truth

The integration source lives in a Home Assistant Core fork at:
- `homeassistant/components/wallbox_beta_ecosmart/` on branch `feat/-wallbox-add-ecosmart`

This repository is generated automatically by a sync script — do not edit `custom_components/wallbox_beta_ecosmart/` directly; changes will be overwritten on the next sync.
