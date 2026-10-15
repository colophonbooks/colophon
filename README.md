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

## Development

Colophon is built with Flutter 3.47 or later (stable). See [BUILDING.md](BUILDING.md) for how to set up each OS and build the app, and [docs/design/](docs/design/basic-design.md) for the design documents.

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
  services/                Logic independent of the UI (ISBN, covers, search, export/import, ISBN lookup)
  state/                   State the screens depend on (settings, book list)
  ui/                      Screens
  l10n/                    UI strings for each language (app_*.arb)
test/                      Automated tests
```

## Where data is stored

Your library is saved as `colophon.db` (SQLite) in the app's data folder:

- Windows: `%APPDATA%\colophonbooks\Colophon\`
- macOS: `~/Library/Containers/io.github.colophonbooks.colophon/Data/Library/Application Support/io.github.colophonbooks.colophon/`
- Linux: `~/.local/share/io.github.colophonbooks.colophon/` (Flatpak: `~/.var/app/io.github.colophonbooks.colophon/`)

### Deleting your data

**Settings → Data → Delete all data** in the app erases all books, notes, and settings and starts over (with a two-step confirmation). What happens on uninstall depends on the OS:

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

## Data structure prepared for syncing between devices

To prepare for a future sync feature (via Google Drive, only when the user turns it on):

- Deleted books and notes keep their rows, with the deletion time recorded in `deleted_at` (so that deletions can reach other devices). Their content (cover image, note text) is removed
- Books and notes are matched by `uuid`, and `updated_at` decides which version is newer
- Renaming or deleting a tag updates `updated_at` of the books that have that tag
- "Replace all" import marks books that are not in the file as deleted

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

## License

Colophon is released under the [MIT License](LICENSE). The third-party packages it uses are distributed under their own licenses (BSD-3-Clause, MIT, Apache-2.0, and MPL-2.0); their notices are bundled with the app and can be viewed under **Settings → Open source licenses**.
