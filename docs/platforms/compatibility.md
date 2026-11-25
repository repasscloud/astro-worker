# Platform compatibility

| Platform | Runner | Baseline integration |
| --- | --- | --- |
| Android | Flutter native | Shared calculations and settings. Four Astro Worker home-screen widgets. |
| iOS | Flutter native | Shared calculations and settings. WidgetKit and Lock Screen widgets are tracked. |
| macOS | Flutter native | Shared calculations and settings. Moon WidgetKit extension on macOS 14 and later with App Group signing. |
| Windows | Flutter native | Shared calculations and settings. Widgets Board evaluation is tracked. |
| Web | Flutter JavaScript | Responsive dashboard, manifest and offline packaging script. |

See [CI runs](https://github.com/repasscloud/astro-worker/actions/workflows/validate.yml) and the [build verification issue](https://github.com/repasscloud/astro-worker/issues/2). Signed distribution and widget hardware verification are separate acceptance checks.

The [non-iOS matrix](https://github.com/repasscloud/astro-worker/actions/runs/45480181627) passed on Android, macOS, Web and Windows. The Chromium smoke test also checks installability. Playwright Firefox 159 and WebKit 27.2 rendered cached production builds with the server unavailable, then activated an upgrade and a rollback after closing the old client. Standalone installation through desktop and Android browser menus is tracked separately in [#17](https://github.com/repasscloud/astro-worker/issues/17).
