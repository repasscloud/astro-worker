# Architecture

`lib/domain` defines calculation interfaces, UTC events, sky positions, civil time and numerology. `lib/infrastructure` adapts Astronomia, preferences and bundled editorial text. `lib/app` owns application composition, navigation and settings. `lib/features` renders observatory views. `lib/shared` contains reusable graphics. `lib/platform` defines the widget snapshot and publishing boundary.

Startup supplies the engine, preferences, content and clock explicitly. The sky snapshot is reused for the selected UTC minute. The event API takes a bounded interval and returns sorted UTC instants. Longer event solvers should support cancellation and bounded chunks on the browser, with native isolate work evaluated by benchmark.

Stateful Flutter widgets currently own shell and view state. Riverpod would support shared async providers and selective observation as more screens and native integrations become independent. The current shell has one state owner and constructor injection, so the foundation uses Flutter state directly.
