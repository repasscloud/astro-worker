# Local astronomy reminders

Astro Worker can schedule reminders on Android and macOS. Enable them in Settings and grant system notification permission. Choose Moon phases, lunar apsides, eclipses, and seasonal events. Reminders can appear at the event or 15 or 60 minutes earlier. Quiet hours use the selected display timezone and skip reminders in that window.

The app refreshes a plan of up to 48 reminders over the next 90 days on opening, resuming, or changing the reminder or timezone settings. Times and IDs use UTC events. On Android, the next permitted alarm is set without requesting exact alarms, so delivery can be delayed by the OS. A receiver restores scheduling after reboot or an app update and reevaluates the quiet window after timezone and clock changes. On macOS, the notification centre holds UTC requests and the app reconciles the plan when it resumes.

Opting out clears pending reminders. The app respects revocation of system permission. Reminder consent and preferences are local to the device and excluded from settings backups. No server receives events or preferences.

On the API 35 Android emulator, enabling reminders registered one app alarm. The next alarm was present after a reboot without opening the app. Revoking notification permission and reopening cancelled the pending alarm. Fixed Adelaide DST fixtures cover both occurrences of a repeated local time, and planner checks cover stable IDs, disabled reminders, and the plan limit.
