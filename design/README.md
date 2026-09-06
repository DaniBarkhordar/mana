# Design

The app's screens as a Claude Design canvas: https://claude.ai/code/artifact/a91fc23e-7257-4307-86a3-ae1fe38a24c0

`build_canvas.py` generates every artboard in `canvas/` from the same values as
`app/lib/theme/tokens.dart`. When a token changes, change it in the app first,
mirror it in the script, and re-run:

```bash
python3 design/build_canvas.py
```

The artboards are static mockups. The numbers on them come from the app's own
equations for one persona (178 cm, 34, male, 78.4 kg, 500 Ω) so the screens and
the tests agree.
