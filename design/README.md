# Design

The app's screens as a Claude Design canvas: https://claude.ai/code/artifact/a91fc23e-7257-4307-86a3-ae1fe38a24c0

`build_canvas.py` generates every artboard in `canvas/` from the same values as
`app/lib/theme/tokens.dart`. When a token changes, change it in the app first,
mirror it in the script, and re-run:

```bash
python3 design/build_canvas.py
```

The artboards are static mockups. The numbers on them come from the app's own
equations for one persona (178 cm, 34, male, 78.7 kg, 500 Ω) — the same persona
`app/test/screenshots/screenshot_test.dart` seeds, so the canvas and the real
screens can be compared side by side.

Artboards: Today (light and dark), Onboarding, Weigh food, Photo scan results,
Cooking oil, Body, Settings, Recipes (planned) and a Components sheet.
