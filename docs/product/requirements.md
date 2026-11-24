# Astro Worker product requirements

This is the target scope. See the roadmap for implementation status.

## 3. Product principles

The application should be:

- Offline-first.
- Privacy-first.
- Cross-platform.
- Lightweight.
- Accessible.
- Responsive.
- Deterministic where possible.
- Independent of external services for core functionality.
- Free from unnecessary dependencies.
- Suitable for long-term maintenance.

The initial application must not require:

- User registration.
- Authentication.
- Backend infrastructure.
- Cloud databases.
- External astrology APIs.
- Advertising.
- Analytics or tracking services.
- Subscriptions.
- AI or LLM services.

All core astronomical calculations should execute locally on the user's device, including within the web browser.

Internet connectivity must not be required for normal operation after the required application resources have been installed or cached.

Clearly distinguish between scientifically calculated astronomical information and traditional astrological, spiritual or numerological interpretations.

Do not present spiritual interpretations as scientifically established facts.

## 4. Platform support

Maintain a single shared Flutter application wherever practical.

| Platform | Application | Additional integration |
|---|---|---|
| Android | Native Flutter application | Home-screen widgets, notifications |
| iOS | Native Flutter application | Home-screen widgets, Lock Screen widgets, notifications |
| macOS | Native Flutter desktop application | Desktop and Notification Centre widgets where supported, notifications |
| Windows | Native Flutter desktop application | Investigate Windows Widgets integration and supported alternatives |
| Web | Responsive Flutter web application | Installable PWA, offline operation |

Do not assume that every native feature is available on every platform.

Use platform capability detection and abstractions to ensure unsupported functionality is gracefully hidden or disabled.

Platform-specific integrations must not cause builds for unrelated platforms to fail.

The application must support:

- Mobile portrait and landscape orientations.
- Tablet layouts.
- Resizable desktop windows.
- Responsive browser layouts.
- Keyboard navigation.
- Mouse and touch interaction.
- Screen readers.
- Dynamic text scaling.
- Light and dark themes.

## 5. Astronomical calculation engine

Investigate Swiss Ephemeris as the primary astronomical calculation engine.

Review the official documentation, available source code, licensing terms, supported calculation ranges and existing Flutter/Dart bindings.

Official reference:

- https://www.astro.com/swisseph/
- https://github.com/aloistr/swisseph

Investigate existing Dart packages, including `sweph`, but do not select a package solely because it exists.

Evaluate:

- Maintenance activity.
- Platform compatibility.
- Numerical accuracy.
- Licensing.
- Native library distribution.
- Ephemeris data requirements.
- Thread safety.
- Performance.
- Web compatibility.
- Binary size.
- Long-term maintainability.

Native platforms may use Dart FFI and compiled native libraries.

Web must use an appropriate browser-compatible implementation, potentially WebAssembly or another validated calculation engine.

Do not attempt to use native Dart FFI directly within a browser.

Investigate how the necessary ephemeris data files can be packaged, loaded, cached and versioned across all five platforms.

### 5.1 Licensing

Astro Worker and the planned Swiss Ephemeris integration follow AGPL-3.0.
Qualify bindings, binaries, data and corresponding source per channel.

Source, self-compiled builds and web access are free. Planned official native
builds are one-time purchases in AUD. Android and iOS are $4.99 each. macOS
and Windows are $7.99 each. Every platform's features are available to users
who compile that platform themselves. Distribution has no ads, accounts,
subscriptions, in-app purchases or custom activation.

See the [distribution decision](../decisions/0003-agpl-distribution.md).

### 5.2 Calculation abstraction

The application must not be tightly coupled to a specific Swiss Ephemeris package.

Establish interfaces and domain models for:

- Astronomical calculations.
- Celestial body positions.
- Lunar calculations.
- Solar calculations.
- Astrological calculations.
- Astrological event detection.
- Geographic calculations.
- Ephemeris data management.

The application must be capable of replacing its underlying astronomical calculation implementation without rewriting the presentation layer.

Use explicit dependency injection.

Any mock calculation provider must be restricted to development, demonstration and testing contexts and must never silently supply fictional astronomical results in production.

## 6. Core astronomical functionality

Implement support for arbitrary dates and times within the verified supported calculation range of the underlying engine.

Users must be able to:

- View current information.
- Select a historical date.
- Select a future date.
- Select a specific time.
- Return immediately to the current date and time.

### 6.1 Celestial bodies

Support, where provided by the calculation engine:

- Sun
- Moon
- Mercury
- Venus
- Mars
- Jupiter
- Saturn
- Uranus
- Neptune
- Pluto
- Chiron
- North Node
- South Node
- Mean and true lunar nodes
- Additional commonly used astrological bodies where appropriate

For each supported celestial body, provide relevant information such as:

- Ecliptic longitude.
- Ecliptic latitude.
- Zodiac sign.
- Position within zodiac sign.
- Degrees, minutes and seconds.
- Apparent movement speed.
- Direct or retrograde movement.
- Stationary events.
- Distance from Earth where available.
- Right ascension.
- Declination.
- Previous zodiac transition.
- Next zodiac transition.

Clearly identify the coordinate systems, units, calculation flags and conventions being used.

### 6.2 Moon

The Moon should be a prominent feature of the application.

Support:

- Current lunar phase.
- Illumination percentage.
- Lunar age.
- Current zodiac sign.
- Position within zodiac sign.
- Waxing or waning status.
- Previous and next new Moon.
- Previous and next full Moon.
- Previous and next first quarter.
- Previous and next last quarter.
- Moonrise and moonset.
- Lunar distance.
- Lunar perigee and apogee.
- Lunar eclipses.
- Zodiac ingress events.
- Void-of-course Moon, using a documented and configurable astrological definition.

Support the eight commonly recognised lunar phases:

1. New Moon
2. Waxing Crescent
3. First Quarter
4. Waxing Gibbous
5. Full Moon
6. Waning Gibbous
7. Last Quarter
8. Waning Crescent

Provide accurate graphical lunar representations.

Account for Northern and Southern Hemisphere viewing conventions and, where appropriate, observer-dependent lunar orientation.

Do not merely mirror a generic Moon image and describe it as an exact local observation.

### 6.3 Sun

Support:

- Current zodiac sign.
- Solar longitude.
- Sunrise.
- Sunset.
- Solar noon.
- Daylight duration.
- Solstices.
- Equinoxes.
- Solar eclipses.
- Zodiac ingress events.
- Civil, nautical and astronomical twilight.

Location-dependent calculations must account for latitude, longitude, timezone and relevant astronomical conventions.

Handle polar day, polar night and locations where rise or set events do not occur on the selected date.

### 6.4 Planetary retrogrades

Support:

- Currently retrograde planets.
- Upcoming retrograde periods.
- Previous retrograde periods.
- Retrograde start date and time.
- Retrograde end date and time.
- Stationary retrograde events.
- Stationary direct events.
- Retrograde duration.
- Zodiac sign associated with the event.

Do not use hardcoded annual retrograde calendars.

Calculate events using the astronomical calculation engine.

### 6.5 Astrological aspects

Support major aspects:

| Aspect | Angle |
|---|---:|
| Conjunction | 0° |
| Sextile | 60° |
| Square | 90° |
| Trine | 120° |
| Opposition | 180° |

Also investigate support for:

- Semi-sextile.
- Semi-square.
- Quintile.
- Sesquiquadrate.
- Quincunx.
- Biquintile.

Support configurable aspect orbs.

Identify:

- Applying aspects.
- Separating aspects.
- Exact aspects.
- Active aspects.
- Upcoming aspects.
- Previous aspects.

Handle angular wraparound correctly.

Use reliable event-solving algorithms rather than relying exclusively on daily sampling, which may miss short-duration events.

### 6.6 Zodiac systems

Support:

- Tropical zodiac.
- Sidereal zodiac.

Investigate supported ayanamsa systems and document their differences.

Default to the tropical zodiac unless the user changes their preference.

Ensure the selected zodiac system is applied consistently throughout the application, including widgets and notifications.

### 6.7 Astronomical and astrological calendar

Provide a calculated calendar containing:

- Lunar phases.
- Solar eclipses.
- Lunar eclipses.
- Planetary retrograde events.
- Planetary stations.
- Zodiac ingress events.
- Significant planetary aspects.
- Solstices.
- Equinoxes.
- Lunar perigee and apogee.

Support daily, weekly, monthly and annual views.

Support filtering by event category and celestial body.

Allow users to select an event to view additional information.

Provide optional export of selected events to an `.ics` calendar file.

## 7. Numerology

Implement numerology independently of the astronomical calculation engine.

Support:

- Universal day number.
- Universal month number.
- Universal year number.
- Personal day number.
- Personal month number.
- Personal year number.
- Life path number.
- Birthday number.
- Additional numerology calculations where appropriate.

Document the calculation methodology.

Support configurable treatment of master numbers, including 11, 22 and 33.

Do not imply that all numerology traditions use identical calculation methods.

Provide locally stored interpretations for supported numbers.

Personal calculations must remain optional and must not require an account.

## 8. Daily colour and spiritual information

Provide an optional daily spiritual overview containing:

- Colour of the day.
- Daily number.
- Daily affirmation.
- Daily intention.
- Reflection prompt.
- Associated spiritual themes.
- Current Moon interpretation.
- Current astrological themes.

Use locally stored content and deterministic calculation or selection rules.

Do not require an external content generation service.

Document how daily colours and spiritual content are selected.

Clearly distinguish editorial or traditional associations from astronomical calculations.

Store interpretations in structured, versioned content files rather than embedding large volumes of text directly into application code.

Establish a content architecture that supports future translations and additional interpretation systems.

## 9. Location, dates and timezones

Most geocentric astronomical calculations do not require the user's geographic location.

Only request or use geographic information when functionality requires it.

Support:

- Automatic device location, where authorised.
- Manual latitude and longitude.
- Manual location selection.
- Device timezone.
- Manual timezone selection.
- UTC display.
- Local time display.
- Daylight-saving transitions.

Investigate an appropriately licensed offline location catalogue if location search is implemented.

Do not introduce an external geocoding dependency without documenting why it is required.

Internally, use consistent UTC-based timestamps for astronomical events.

Convert timestamps to the user's selected timezone at the presentation boundary.

Test:

- Daylight-saving changes.
- Leap years.
- Midnight boundaries.
- International Date Line.
- Fractional timezone offsets.
- Northern and Southern Hemisphere locations.
- Historical timezone changes where supported.

Ensure Australian timezones, including Australia/Adelaide, are correctly handled.

## 10. Personal astrology

Design the architecture to support personal astrology without making it a requirement for the initial application.

Future functionality should include:

- Natal charts.
- Sun sign.
- Moon sign.
- Ascendant.
- Descendant.
- Midheaven.
- Imum Coeli.
- Astrological houses.
- Natal planetary positions.
- Natal aspects.
- Personal transits.
- Solar return charts.
- Relationship synastry.
- Composite charts.

Investigate common house systems, including:

- Placidus.
- Whole Sign.
- Equal House.
- Koch.
- Porphyry.
- Regiomontanus.
- Campanus.

Handle house systems that cannot be reliably calculated at certain latitudes.

Personal birth data must remain optional and locally stored.

Do not fabricate a birth time if the user does not know it. Clearly identify which calculations cannot be reliably performed without an accurate birth time.

Create appropriate GitHub issues and milestones for personal astrology functionality, even where implementation is deferred.

## 11. Application screens

Establish responsive navigation and the following application areas.

### Today

The primary application dashboard.

Display:

- Current date and time.
- Current Moon phase.
- Moon illumination.
- Moon zodiac sign.
- Sun zodiac sign.
- Active planetary retrogrades.
- Significant active aspects.
- Upcoming astronomical events.
- Daily number.
- Colour of the day.
- Optional daily spiritual interpretation.

### Moon

Display:

- Large graphical Moon representation.
- Phase and illumination.
- Current zodiac position.
- Lunar age.
- Lunar distance.
- Moonrise and moonset.
- Next significant lunar event.
- Interactive lunar cycle.
- Monthly lunar calendar.
- Historical and future date selection.

### Planets

Display:

- All supported celestial bodies.
- Current zodiac position.
- Degrees within zodiac sign.
- Direct or retrograde movement.
- Upcoming zodiac transitions.
- Relevant astronomical measurements.

Selecting a celestial body should open a detailed view.

### Calendar

Display calculated astronomical and astrological events.

Support:

- Day view.
- Week view.
- Month view.
- Year view.
- Event list view.
- Event filtering.
- Event detail.
- Calendar export.

### Astrology

Display:

- Zodiac information.
- Current planetary aspects.
- Planetary alignments.
- Zodiac wheel.
- Astrological interpretations.
- Personal astrology functionality when implemented.

### Numerology

Display:

- Universal numbers.
- Personal numbers, where configured.
- Calculation explanations.
- Number interpretations.
- Date selection.

### Spiritual

Display optional spiritual information, including:

- Daily affirmation.
- Daily colour.
- Daily intention.
- Reflection prompts.
- Spiritual interpretations.

### Widgets

Display:

- Available widget types.
- Widget previews.
- Supported widget sizes.
- Configuration options.
- Platform-specific installation instructions.
- Current platform capabilities.

### Settings

Provide configuration for:

- Application theme.
- Colour palette.
- Language.
- Location.
- Timezone.
- Date and time formats.
- Zodiac system.
- Ayanamsa.
- Aspect orbs.
- Numerology preferences.
- Spiritual content visibility.
- Notification preferences.
- Widget preferences.
- Data management.
- Application information.
- Licences.
- Calculation methodology.

## 12. User interface and design system

Establish a consistent and reusable application design system.

The visual direction should be contemporary, celestial and sophisticated without becoming cluttered or difficult to read.

Support:

- Light theme.
- Dark theme.
- System theme.
- Optional celestial theme.
- Configurable accent colours.
- Reusable cards.
- Reusable celestial body symbols.
- Reusable zodiac symbols.
- Responsive typography.
- Consistent spacing.
- Accessible colour contrast.

Investigate an initial palette based on:

- Near-black celestial backgrounds.
- Deep midnight blue.
- Muted purple.
- Gold accents.
- Neutral whites and greys.

Do not hardcode colours throughout individual screens.

Build reusable components for:

- Moon phase visualisation.
- Celestial body cards.
- Zodiac indicators.
- Retrograde indicators.
- Event cards.
- Event countdowns.
- Daily colour cards.
- Numerology cards.
- Astrological wheels.
- Date and time selectors.

Prefer vector graphics and programmatic rendering where practical.

Ensure zodiac and celestial symbols render consistently across all supported operating systems.

## 13. Native widgets

Native widgets are a core product feature, not an optional afterthought.

Users should be able to access useful information without opening the main application.

### 13.1 Widget types

Establish support for:

| Widget | Information |
|---|---|
| Moon Phase | Graphical Moon, phase and illumination |
| Moon Sign | Zodiac sign, position and next transition |
| Sun Sign | Current zodiac sign and position |
| Daily Number | Universal or personal day number |
| Daily Colour | Colour swatch, name and interpretation |
| Daily Affirmation | Current affirmation |
| Retrograde Tracker | Currently retrograde planets |
| Planetary Positions | Selected planetary positions |
| Daily Astrology | Combined solar, lunar and planetary summary |
| Cosmic Calendar | Upcoming significant events |
| Next Full Moon | Date, time and countdown |
| Next New Moon | Date, time and countdown |
| Sun and Moon | Sunrise, sunset, moonrise and moonset |
| Zodiac Wheel | Current astrological positions |
| Spiritual Overview | Daily number, colour and intention |

Support small, medium and large widget configurations where the operating system permits them.

Provide configurable content where supported.

Widgets must support deep linking into the relevant application screen.

### 13.2 Android

Investigate and implement native Android home-screen widgets using:

- Kotlin.
- Jetpack Glance or another appropriate native widget implementation.
- Flutter-to-native shared data.
- Android widget configuration.
- Background update scheduling.

Support multiple independently configured widget instances.

### 13.3 iOS

Investigate and implement:

- WidgetKit.
- SwiftUI widget layouts.
- App Groups.
- Timeline providers.
- Home-screen widgets.
- Lock Screen widgets.
- Configurable widgets using supported native APIs.

Support the available widget families appropriate to each widget type.

### 13.4 macOS

Investigate and implement:

- WidgetKit.
- macOS desktop widgets.
- Notification Centre widgets.
- Shared application data.
- Native widget timelines.

Reuse iOS widget implementation components where supported and practical.

### 13.5 Windows

Investigate the current Windows Widgets platform and its distribution, packaging and integration requirements.

Determine whether native Windows Widgets integration is practical for the application's supported Windows versions.

Document any restrictions associated with:

- MSIX packaging.
- Widget providers.
- Windows App SDK.
- Operating system versions.
- Microsoft Store distribution.

Where native widget integration is unavailable, investigate appropriate alternatives such as a compact desktop window or configurable dashboard mode.

Do not describe an application window as a native Windows widget.

### 13.6 Web

Provide:

- Responsive dashboard cards.
- Configurable dashboard layout where appropriate.
- Installable PWA support.
- Offline application resources.
- Browser-compatible astronomical calculations.

Investigate browser notifications and background capabilities.

Do not promise operating-system home-screen widgets from a web application where no supported mechanism exists.

### 13.7 Widget data and updates

Evaluate the Flutter `home_widget` package and other appropriate integration mechanisms.

Widgets must not depend on the main application being opened every day.

Astronomical events are predictable, allowing the application to precompute future data.

Design a versioned widget data contract supporting:

- Current calculated values.
- Future astronomical events.
- Future lunar phases.
- Future zodiac transitions.
- Daily numerology.
- Daily colours.
- Daily spiritual content.
- User preferences.
- Timezone information.
- Generation timestamps.
- Data validity periods.

Investigate precomputing a rolling window of up to 365 days of relevant information.

Do not store unnecessary high-frequency calculations if events or interpolated values provide equivalent accuracy.

Native widgets should consume precomputed timelines wherever practical.

Account for operating-system widget refresh restrictions.

Do not promise exact real-time refreshes or guaranteed background execution.

Provide graceful handling of:

- Stale widget data.
- Expired timelines.
- Timezone changes.
- Location changes.
- Application upgrades.
- Missing shared data.
- Device restarts.
- Multiple widget instances.

## 14. Notifications

Provide optional local notifications for:

- Full Moon.
- New Moon.
- Lunar eclipses.
- Solar eclipses.
- Planetary retrograde commencement.
- Planetary retrograde completion.
- Zodiac transitions.
- Significant planetary aspects.
- Solstices.
- Equinoxes.
- Daily spiritual overview.
- Daily numerology.
- Personal transits when implemented.

All notifications must be opt-in.

Allow users to configure categories and notification timing.

Account for platform notification limits and scheduling restrictions.

Use rolling notification scheduling rather than attempting to schedule unlimited future notifications.

Handle timezone changes, daylight-saving changes, device restarts and revoked permissions.

No push notification infrastructure is required for the initial release.

## 15. Data storage and privacy

Investigate suitable cross-platform local storage solutions.

Evaluate:

- Drift.
- SQLite.
- Browser-compatible SQLite implementations.
- IndexedDB.
- Shared preferences.
- Platform-native shared widget storage.

Select storage mechanisms based on actual requirements.

Astronomical calculations are reproducible and should not require an unnecessarily large persistent database.

Persist:

- User preferences.
- Optional location information.
- Optional birth information.
- Widget configuration.
- Notification configuration.
- Relevant calculation caches.
- Ephemeris resource metadata.
- Interpretation content metadata.

Support appropriate versioning and migrations.

Provide the ability to:

- Clear cached astronomical information.
- Clear personal information.
- Reset settings.
- Reset the application.
- Export personal settings where appropriate.
- Import settings where appropriate.

Do not transmit personal birth information or geographic location to external services without explicit user consent.

Do not store unnecessary personal information.

## 16. Application architecture

Use a modular, feature-oriented architecture with clear boundaries between:

- Presentation.
- Application services.
- Domain models.
- Calculation engines.
- Data persistence.
- Platform integrations.
- Shared components.
- Content resources.

Use an appropriate and maintained state management solution.

Evaluate Riverpod or equivalent approaches.

Avoid unnecessary abstraction, excessive boilerplate and premature optimisation.

An indicative repository structure is:

```text
/
├── .github/
│   ├── workflows/
│   └── ISSUE_TEMPLATE/
├── android/
├── ios/
├── macos/
├── windows/
├── web/
├── assets/
│   ├── branding/
│   ├── content/
│   ├── ephemeris/
│   ├── fonts/
│   └── graphics/
├── docs/
│   ├── architecture/
│   ├── calculations/
│   ├── development/
│   ├── product/
│   ├── platforms/
│   ├── testing/
│   └── decisions/
├── lib/
│   ├── app/
│   ├── core/
│   ├── domain/
│   ├── infrastructure/
│   ├── features/
│   │   ├── today/
│   │   ├── moon/
│   │   ├── planets/
│   │   ├── calendar/
│   │   ├── astrology/
│   │   ├── numerology/
│   │   ├── spiritual/
│   │   ├── birth_chart/
│   │   ├── widgets/
│   │   └── settings/
│   ├── platform/
│   └── shared/
├── test/
├── integration_test/
├── scripts/
├── AGENTS.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── README.md
├── SECURITY.md
├── analysis_options.yaml
└── pubspec.yaml
```

Treat this structure as indicative. Adjust it where necessary and document the final architectural decisions.
