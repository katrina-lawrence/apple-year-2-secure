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

### ZIP backups

In Settings → Backups, Export Notes Backup saves the loaded notes and follow-ups as a ZIP containing `notes.json`. Refresh Notes before exporting to include the latest server changes.

Import Notes Backup restores missing records to the signed-in account using `POST /backups/restore`, then refreshes the app. It preserves IDs, summaries, dates, follow-up links and completion state. Existing records are skipped, so repeated imports do not duplicate records or overwrite newer edits. Use the updated `catalyst-server` backend with this app.

To check restoration: add a test note, export a backup, delete that test note, then import the same ZIP. The note should reappear and remain after refreshing. Import the ZIP again to verify that no duplicates appear.
