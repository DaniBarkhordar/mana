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

Artboards, first row: Today, Onboarding, Weigh food, Photo scan results, Cooking
oil, Body, Settings. Second row: Today (dark), Pair a scale, Account, Mananu
Plus, Connected sources, Recipes, and a Components sheet. Third row: Progress,
Progress (dark), Goals, and two onboarding steps — the goal choice and the
summary with the starting target. Every screen exists in the app;
`app/test/screenshots/` renders the real ones for comparison.

The Progress artboards use the week `_seedWeek` in that test seeds: six
weighed days, two with an estimated meal out, nothing logged yet on the Sunday
the tab is opened. Goals and the onboarding summary give the same person a
goal — lose 5 kg at 0.5 kg a week — and their numbers are worked by hand from
`energy_target.dart`: Cunningham from fat-free mass once a reading exists,
Mifflin-St Jeor before one does.
