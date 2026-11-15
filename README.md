# Recipe Book

A recipe app written in Flutter and tested on Android. I built it for a Flutter hands-on test: keep recipes on the phone, give each one a photo, ingredients and steps, and filter the list by type.

It starts with 17 sample recipes so the screens aren't empty. Whatever you add or change is saved in SQLite on the device and is still there after a restart.

## What it does

- The recipe list, with a filter by type, search by name or ingredient, and sorting (newest, oldest, A to Z).
- Adding and editing a recipe: a photo from the camera or the gallery, a name, a type, and ingredients and steps that you can add, edit, delete and drag into a new order.
- A detail page with the photo, ingredients and steps. Edit opens the same form, filled in. Delete asks first.
- Favourites, with a heart on every recipe and a tab for the ones you've hearted.
- Accounts: sign up and log in on the device, and stay logged in until you log out.
- A Profile tab with a few numbers about your cookbook, a light or dark theme, and the status of the recipe types list.

The layout follows the screen. A phone gets one column of cards, a tablet gets two or three, and in landscape the bottom bar becomes a side bar.

## Running it

You need a recent Flutter. I used 3.50.0 (Dart 3.14), and `pubspec.yaml` asks for Dart 3.14 or newer, so an older Flutter will refuse to resolve the packages.

```bash
flutter pub get
flutter run
```

There is no default login. Tap "Create an account" on the first screen.

To build an APK:

```bash
flutter build apk --release
```

I work on Windows and ran it on an Android emulator (Pixel 8). The iOS project is in the repo, but I haven't built it.

## The recipe types file

`assets/recipetypes.json` is bundled with the app and fills the type dropdowns. It looks like this:

```json
{ "recipeTypes": [ { "id": 1, "name": "Breakfast" } ] }
```

If your file is shaped differently, `RecipeType.listFromJson` in `lib/models/recipe_type.dart` is the one place to change.

On launch the app also tries to download the copy of that file in this repo (the `main` branch). It keeps the last good download in SQLite and uses the bundled file when it's offline, so the dropdown is never empty. That means editing the file here changes the list in the app the next time it starts. The Profile tab shows which copy is in use and has a Refresh button.

## How the code is organised

It's MVVM with `provider`. Screens watch a ViewModel (a `ChangeNotifier`), and the ViewModel talks to repositories through interfaces. The repositories are the only code that touches SQLite, secure storage, the network or the asset bundle. `get_it` wires it all together in `lib/core/di/locator.dart`, and the tests swap in fakes.

Recipes reach the screens as a `Stream`. The repository emits a fresh list after every insert, update and delete, and the pages show it with `StreamBuilder`, so the list, the detail page and the Profile numbers update without any manual refresh. The recipe types use a `FutureBuilder`.

```
lib/
  main.dart, app.dart   start-up, theme, the login gate
  core/                 theme, get_it setup, the URL of the types file
  models/               Recipe, RecipeType, User
  data/
    local/              SQLite database and sample recipes, photo storage,
                        password hashing, session storage
    remote/             ApiClient (http with a timeout)
    repositories/       the interfaces and their implementations
  viewmodels/           one ChangeNotifier per area of the app
  views/                screens and widgets
test/                   unit and widget tests
integration_test/       one end-to-end test
```

## Where to find each part of the test

| Asked for | Where |
|---|---|
| Storage | `lib/data/local/app_database.dart` (SQLite, sqflite) |
| `recipetypes.json` in a `DropdownButton` | `assets/recipetypes.json`, `lib/views/recipes/type_filter_dropdown.dart`, `lib/views/recipes/recipe_form_page.dart` |
| Sample recipes | `lib/data/local/seed_data.dart`, inserted when the database is first created |
| List filtered by type | `lib/views/recipes/recipe_list_page.dart`, `lib/viewmodels/recipe_list_view_model.dart` |
| Create a recipe | `lib/views/recipes/recipe_form_page.dart`, `lib/viewmodels/recipe_form_view_model.dart`, `lib/data/local/image_storage.dart` |
| Detail page, update, delete | `lib/views/recipes/recipe_detail_page.dart` |
| Reactive programming | `lib/data/repositories/recipe_repository.dart` (the stream), `StreamBuilder` in the list, detail and Profile pages |
| Architecture pattern | `lib/viewmodels/` and `lib/views/` |
| Authentication | `lib/data/repositories/auth_repository.dart`, `lib/data/local/password_hasher.dart`, `lib/data/local/session_store.dart`, `lib/views/auth/login_page.dart` |
| Networking | `lib/data/remote/api_client.dart`, `lib/data/repositories/recipe_type_repository.dart` |
| Dependency injection | `lib/core/di/locator.dart` |
| Unit and UI tests | `test/`, `integration_test/` |

## Tests

There are over 150 unit and widget tests. They cover the models, the repositories (against an in-memory SQLite database), the ViewModels (with `mocktail`) and the screens. Most screens are also checked for overflow at 320x568, 568x320 and 1024x768, and the list and Profile pages again with doubled text size.

```bash
flutter test
```

The end-to-end test signs up, adds a recipe, hearts it, edits it, deletes it and logs out. It needs a running emulator or device, and it creates a throwaway account each time.

```bash
flutter test integration_test/app_test.dart -d <device id>
```

## Choices and limits

Login is local. Accounts live in the phone's database, passwords are stored as a salted SHA-256 hash, and the session is kept with `flutter_secure_storage` (the Android Keystore). There is no server, so there is no password reset. One round of SHA-256 is quick to guess against, so with a real backend I'd hash on the server with something slow like Argon2 and hand out tokens.

Recipes and favourites don't belong to a user. Anyone who logs in on the same phone sees the same cookbook. Per-user recipes would need a `user_id` column and a database upgrade.

Photos are copied into the app's documents folder and the recipe stores the full path. On iOS that folder's path can change after an app update, so relative paths would be safer there. There's a comment about it in `lib/data/local/image_storage.dart`.

The recipe types are loaded once per launch, so a change to the file on GitHub shows up after a restart or after Refresh on the Profile tab.

## Photo credits

Where the sample photos came from is noted in `assets/images/recipes/CREDITS.md`. A few of the sources still need to be added.
