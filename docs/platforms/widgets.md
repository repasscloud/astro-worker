# Platform widgets

Android provides four launcher widgets through AppWidgetProvider and RemoteViews. Long-press a blank area of the launcher, open Widgets, and look under Astro Worker.

| Widget | Default launcher cells | Opens |
| --- | --- | --- |
| Moon Glance | 1 × 1 | Moon phase details |
| Lunar Reflection | 4 × 2 | Phase-inspired reflection |
| Lunar Colour | 2 × 2 | Colour name and association |
| Moon Phase & Info | 4 × 2 | Previous and upcoming lunar phases |

The launcher controls final widget dimensions. The Moon illustrations follow the hemisphere preference, and Lunar Reflection follows the spiritual content preference. The app prepares a 48-hour offline timeline when opened or resumed. Android controls when placed widgets refresh. When the timeline expires, the widgets offer a tap to reopen the app.

iOS and macOS require distinct WidgetKit targets, App Group sharing and system-managed timelines. Windows Widgets Board needs host capability and packaging investigation. Web supports the app dashboard with install and offline caching through a manifest and service worker.

The app also includes Moon and universal-day previews. Hardware verification and further platform work remain tracked in the [widget milestone](https://github.com/repasscloud/astro-worker/milestone/5).

Samsung Galaxy A14 5G smoke verification confirmed all four providers registered, Moon Glance rendered artwork in a placed 1 × 1 cell, and tapping that widget opened Moon details. Launch actions for the other three widgets reached their corresponding app panels. Launcher resizing and real-time offline refresh across a phase change remain release-acceptance checks.
