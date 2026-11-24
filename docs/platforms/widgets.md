# Platform widgets

Android provides four launcher widgets through AppWidgetProvider and RemoteViews. Long-press a blank area of the launcher, open Widgets, and look under Astro Worker.

| Widget | Default launcher cells | Opens |
| --- | --- | --- |
| Moon Glance | 1 × 1 | Moon phase details |
| Lunar Reflection | 4 × 2 | Phase-inspired reflection |
| Lunar Colour | 2 × 2 | Colour name and association |
| Moon Phase & Info | 4 × 2 | Previous and upcoming lunar phases |

The launcher controls final widget dimensions. The Moon illustrations follow the hemisphere preference, and Lunar Reflection follows the spiritual content preference. The app prepares a 48-hour offline timeline when opened or resumed. Android controls when placed widgets refresh. When the timeline expires, the widgets offer a tap to reopen the app.

iOS WidgetKit integration is tracked separately. The [Windows Widgets Board evaluation](windows-widgets.md) records the packaging and host requirements. Web supports the app dashboard with install and offline caching through a manifest and service worker.

The app also includes Moon and universal-day previews. Hardware verification and further platform work remain tracked in the [widget milestone](https://github.com/repasscloud/astro-worker/milestone/5).

Samsung Galaxy A14 5G smoke verification confirmed all four providers registered, Moon Glance rendered artwork in a placed 1 × 1 cell, and tapping that widget opened Moon details. Launch actions for the other three widgets reached their corresponding app panels. Launcher resizing and real-time offline refresh across a phase change remain release-acceptance checks.

On macOS 14 and later, the embedded Astro Worker Moon WidgetKit extension offers small and medium widgets in the desktop and Notification Centre gallery. Its shared timeline is private to the App Group. Opening the app prepares up to 48 hours of entries, and clicking the widget opens Moon details. Unsigned development builds compile the extension with App Group sharing disabled.

For a signed macOS build, register `com.sisterswithmirrors.astroworker`, `com.sisterswithmirrors.astroworker.MoonWidget`, and the `group.com.sisterswithmirrors.astroworker` App Group for the same Apple team. Copy [WidgetSigning.xcconfig.example](../../macos/Runner/Configs/WidgetSigning.xcconfig.example) to the untracked `WidgetSigning.xcconfig`, then set the team and sign both targets for profiles that grant the group. Verify shared data, desktop and Notification Centre placement, click behaviour, and expiry on a signed installation. [Apple WidgetKit extension guide](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
