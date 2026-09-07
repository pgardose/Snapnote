# Subject Notes

A local-only study notes app: organize notes into **Subjects**, each holding
many **Entries**. Entries can be typed directly or transcribed from a photo
via the Gemini API. Math is preserved as LaTeX (`$...$` inline, `$$...$$` block) and rendered in-app.

## Hard constraints (by design)

- **No login, no cloud sync.** All data lives in a local SQLite database
  (`sqflite`) in the app's documents directory.
- **No PDF/Word export.** Entries are viewed and edited only inside the app.
- **Gemini API, free tier**, used only for photo → text transcription
  (`google_generative_ai`), not OpenAI.
- **Math as LaTeX**, rendered with `flutter_math_fork`.

## Project layout

```
lib/
  models/     Subject, Entry — plain data classes with toMap/fromMap
  data/       DatabaseHelper (sqflite schema + raw CRUD) and
              SubjectRepository / EntryRepository (the API screens use)
  services/   GeminiTranscriptionService, ImageStorageService
  screens/    HomeScreen, SubjectDetailScreen, EntryEditorScreen
  widgets/    SubjectTile, LatexContentView
main.dart     Loads .env, launches HomeScreen
```

Data model:

```
Subject(id, name, createdAt)
Entry(id, subjectId, content, sourceImagePath, createdAt, updatedAt)
```

`subjectId` is a foreign key with `ON DELETE CASCADE`, so deleting a Subject
deletes its Entries.

## Setup

1. Install Flutter (stable channel) and run:
   ```
   flutter pub get
   ```
2. Get a **free** Gemini API key: https://aistudio.google.com/app/apikey
3. Copy the example env file and add your key:
   ```
   cp .env.example .env
   # edit .env, set GEMINI_API_KEY=...
   ```
4. Run the app:
   ```
   flutter run
   ```

`.env` is git-ignored — only `.env.example` is committed.

## Status

This is a scaffold: data layer, services, and full CRUD screens are wired up
and functional, but it hasn't been run against a real Flutter SDK/device in
this environment. Before shipping, run `flutter pub get`, `flutter analyze`,
and test transcription against a real Gemini API key.

Known follow-ups worth doing next:
- Add a proper Markdown/LaTeX split renderer if entries grow richer formatting
  needs beyond plain text + math.
- Add unit tests for `DatabaseHelper` (e.g. with `sqflite_common_ffi`) and for
  `LatexContentView`'s segment parser.
- Handle Android/iOS camera & photo library permissions explicitly (image_picker
  needs `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` on iOS and
  the relevant `<uses-permission>` entries on Android).
