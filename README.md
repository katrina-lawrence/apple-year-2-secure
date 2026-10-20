# My Dental Companion

## Server-Only Runtime

This app runs in server mode only.

### Backend configuration

1. Copy `Dental Notes/BackendConfig.example.plist` to `Dental Notes/BackendConfig.plist`.
2. Set `baseURL` to your backend URL (`http://` or `https://`).
3. Build and run the app (`Debug` and `Release` are both server-enabled).

### Notes

- `Dental Notes/BackendConfig.plist` is gitignored and should remain local to each developer machine.
- Notes and followups are stored in an in-memory SwiftData container (no persistent on-device SwiftData files).
- `Apple Intelligence` processing runs on-device.
- Selecting `Third-party provider` routes note processing to backend `POST /notes/process` using the note ID.
