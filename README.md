# Colophon

[日本語](README.ja.md) | English

A book library app for book lovers. Keep track of the books you own, your reading status, cover images, notes (impressions, learnings, memos, excerpts), tags, and the dates you finished each book.

- Platforms: Windows / macOS / Linux (iPhone / iPad / Android planned)
- Languages: English / 日本語 / 简体中文 / Français / Español / Deutsch / 한국어

## Features

| Feature | Details |
|---|---|
| Book records | Title (required), author, translator, supervisor, publisher, ISBN, edition |
| ISBN lookup | Queries national libraries and Open Library in an order chosen from the ISBN (e.g. Japan → National Diet Library, France → BnF); you choose which fields to apply |
| Covers | Set images manually. Large images (over 2000 px on the long side or over 2 MB) are reduced automatically (can be turned off in Settings) |
| Viewer mode | Open a book read-only: only filled-in fields, notes with their category and page, no editing controls. Switch to edit mode when needed |
| Library views | Switch between a title list and a cover grid. Sort by recently added or by title |
| Reading status | Not set (default), Unread, Reading, Finished. While reading, you can optionally record your progress (%) |
| Finish dates | Record every time you finish a book. Books read twice or more show the count in the list |
| Notes | Add as many as you like. Category (Impressions, Learnings, Memo, Excerpt, Other, or none) and page number are optional. Mark notes as favorites (★) to find them later |
| Tags | Multiple tags per book. Rename or delete tags in the tag manager |
| Search | Search book details and note text. Filter by search fields, status, note category, tags, and finish date |
| Export | Text (for reading, optionally with cover images in a ZIP), JSON + images (ZIP), SQLite |
| Import | Restore from ZIP or SQLite, either replacing everything or adding to your library (duplicates are skipped) |
| Delete all data | Erase all books, notes, and settings from the Settings screen and start over (with a two-step confirmation) |
| Appearance | 6 color themes (Leather, Forest, Ocean, Rose, Monochrome, and Universal for every type of color vision) with light / dark / system brightness |
| Sync (optional) | Keep the same library on several computers through your own Google Drive. Off until you sign in with Google in Settings; syncs automatically after that |

## Development

Colophon is built with Flutter 3.47 or later (stable). See [BUILDING.md](BUILDING.md) for how to set up each OS and build the app, and [docs/design/](docs/design/basic-design.md) for the design documents.

Google Drive sync needs a Google OAuth client ID passed at build time; builds without one simply show sync as unavailable. See "Google Drive sync" in [BUILDING.md](BUILDING.md).

```sh
flutter pub get
flutter run -d windows        # run during development
flutter test                  # run the tests
flutter build windows         # release build → build/windows/x64/runner/Release/
```

## Project structure

```
lib/
  main.dart / app.dart     Startup and app-wide configuration
  models/                  Data types (books, notes, finish dates, etc.)
  data/                    SQLite schema and data access
  services/                Logic independent of the UI (ISBN, covers, search, export/import, ISBN lookup, Google sign-in)
  sync/                    Google Drive sync (data format, merge rules, Drive access, sync engine)
  state/                   State the screens depend on (settings, book list, sync)
  ui/                      Screens
  l10n/                    UI strings for each language (app_*.arb)
test/                      Automated tests
```

## Where data is stored

Your library is saved as `colophon.db` (SQLite) in the app's data folder:

- Windows: `%APPDATA%\colophonbooks\Colophon\`
- macOS: `~/Library/Containers/io.github.colophonbooks.colophon/Data/Library/Application Support/io.github.colophonbooks.colophon/`
- Linux: `~/.local/share/io.github.colophonbooks.colophon/` (Flatpak: `~/.var/app/io.github.colophonbooks.colophon/`)

When Google Drive sync is used, the same folder also holds `sync-state.json` (when this computer last synced) and `sync-backups/` (a backup taken automatically before the first sync, in the export ZIP format; the latest three are kept). The Google sign-in is stored in the OS's secure storage (Windows: an encrypted file in the same folder; macOS: the keychain; Linux: the desktop keyring).

### Deleting your data

**Settings → Data → Delete all data** in the app erases all books, notes, and settings and starts over (with a two-step confirmation). If you are signed in for sync, you also choose whether to delete only on this computer (sync is turned off; Google Drive and your other computers keep their data) or on Google Drive and every computer.

To delete only the copy on Google Drive, open Google Drive in a web browser, go to **Settings → Manage apps → Colophon → Options**, and choose **Delete hidden app data**.

What happens on uninstall depends on the OS:

| Package | Library on uninstall |
|---|---|
| Windows installer | Asks whether to delete it (default: keep) |
| macOS (.dmg) | Kept. Delete it with the in-app option or by removing the folder above |
| Linux Flatpak | Deleted with `flatpak uninstall --delete-data` |
| Linux .deb | Kept. Delete it with the in-app option or by removing the folder above |

See [BUILDING.md](BUILDING.md) for how to build the packages.

Settings such as the display language and automatic cover reduction are stored separately per device and are not included in exports.

## Export format (JSON + images)

The ZIP file contains:

```
books.json
covers/{uuid}.jpg    (only for books with a cover; the extension matches the image format)
```

```json
{
  "format": "colophon",
  "version": 1,
  "exportedAt": "2026-10-14T03:00:00.000Z",
  "books": [
    {
      "uuid": "…",
      "title": "Sapiens: A Brief History of Humankind",
      "author": "Yuval Noah Harari",
      "translator": null,
      "supervisor": null,
      "publisher": "Harper",
      "isbn": "978-0-06-231609-7",
      "edition": null,
      "status": "reading",
      "progress": 40,
      "cover": "covers/….jpg",
      "tags": ["History"],
      "readDates": ["2026-01-02"],
      "notes": [
        { "uuid": "…", "category": "learning", "page": 30, "body": "…", "favorite": true, "createdAt": "…", "updatedAt": "…" }
      ],
      "createdAt": "…",
      "updatedAt": "…"
    }
  ]
}
```

- `status`: `unset` / `unread` / `reading` / `finished`
- `category`: `impression` / `learning` / `memo` / `excerpt` / `other` / `null` (no category)
- Timestamps are ISO 8601 in UTC; finish dates are `yyyy-MM-dd`
- The `uuid` of a book or note identifies the same item across devices (older files without note `uuid`s can still be imported)
- `favorite`: whether the note is a favorite (missing means `false`)

## Google Drive sync

Sync keeps the same library on every computer signed in with the same Google account. It is off until you turn it on.

**Turning it on**: **Settings → Sync → Sign in**. Choose your Google account in the browser and allow access, and the first sync starts right away. If both this computer and Google Drive already have books, you choose how to combine them: **Combine** (books with the same ISBN become one), **Replace with Google Drive**, or **Replace with this computer**. A backup of this computer's library is saved before anything changes.

**What is synced**: books, notes, tags, finish dates, and cover images. Settings such as the display language and color theme stay per computer.

**When it syncs**: a few seconds after the app starts, 30 seconds after your last change (at most 5 minutes after the first change while you keep editing), before the app closes if there are unsent changes, and whenever you press **Sync now**. Temporary failures (for example, no network) are retried automatically.

**When two computers changed the same book**: for each book and for each note, the version saved later wins. Notes added on different computers are all kept. Deletions reach the other computers too.

**Privacy**:

- Your data goes only to your own Google Drive. Colophon has no server of its own
- It is stored in Google Drive's hidden app data folder, which does not appear in the Drive file list and only Colophon can open
- Colophon asks only for permission to use its own app data folder (`drive.appdata`); it cannot see your other files
- **Sign out** stops syncing on that computer and revokes Colophon's access token. Nothing is deleted on the computer or on Google Drive

How it works, in short:

- Deleted books and notes keep their rows with the deletion time in `deleted_at`, so that deletions can reach other devices. Their content (cover image, note text) is removed
- Books and notes are matched by `uuid`, and `updated_at` decides which version is newer. Times are corrected by the difference from Google's server clock
- Renaming or deleting a tag updates `updated_at` of the books that have that tag, so tags travel with their books
- Google Drive holds one file with all records (`colophon-sync.json`) and one file per cover image, named by its SHA-256, so that only changed covers are transferred
- Before uploading, the app checks that no other computer uploaded in the meantime; if one did, it merges again first

## Adding a display language

1. Copy `lib/l10n/app_en.arb` to `app_{language code}.arb` and translate the strings
2. Add one line to `supportedLanguages` in `lib/state/settings_controller.dart`
3. Run `flutter gen-l10n` (it also runs automatically with `flutter run`)

## Book data sources

ISBN lookup uses the following public APIs (no registration required). Each result shows its source.

- [National Diet Library Search](https://ndlsearch.ndl.go.jp/en/) (Japan)
- [Open Library](https://openlibrary.org/developers/api)
- [Library of Congress](https://www.loc.gov/) (SRU)
- [Bibliothèque nationale de France](https://catalogue.bnf.fr/) (SRU; data under the Licence Ouverte)
- [Deutsche Nationalbibliothek](https://www.dnb.de/) (SRU; data under CC0)

## AI assistance

Colophon is developed with the help of an AI coding assistant (Anthropic's Claude, used through Claude Code). Most of the code and documentation was drafted by the assistant. The maintainer reviews and tests every change, decides what is included, and is responsible for the project.

Commits made with the assistant's help end with a `Co-Authored-By:` line naming it. The initial commit does not have this line, but it too was written largely with the assistant.

## License

Colophon is released under the [MIT License](LICENSE). The third-party packages it uses are distributed under their own licenses (BSD-3-Clause, MIT, Apache-2.0, and MPL-2.0); their notices are bundled with the app and can be viewed under **Settings → Open source licenses**.
