

## 1.3.0

- **Generate models from JSON**: `create model:<name> --json '<json>'` (or
  `--from-json <file>`) infers field types from a sample payload — `int`,
  `double`, `bool`, `String`, ISO-8601 strings as `DateTime`, typed `List<T>`,
  and **nested objects / arrays-of-objects as their own generated models**
  (collection keys are singularized, e.g. `orders` → `Order`). Also works with
  `create feature:`.
- **`generate routes`**: discovers every scaffolded feature under
  `lib/presentation` / `lib/features` and regenerates `lib/app/routes/`
  from scratch, wiring a `home` feature to its view (or a `Placeholder`).
  A repair/sync command — `--dry-run` previews the output.
- **`remove <feature|page|screen>:<name>`**: deletes a feature directory and
  surgically unregisters its route (constant + `GoRoute` block + import),
  preserving the rest of the routing file. For `feature:` it also removes the
  generated model and repository (`--keep-data` to keep them). Destructive, so
  it confirms first (`--yes` to skip, `--dry-run` to preview).
- **`--with-test`**: `create model:` / `create feature:` can emit a
  `flutter_test` round-trip test asserting `fromJson`/`toJson` are inverse
  (skipped automatically for models with nested-model fields).
- Generated models now (de)serialize nested models and lists of models
  recursively.

## 1.2.0

- **Claude Code skill, bundled & installable**: ship the `river-cli-flutter`
  skill with the CLI and install it into a project (or globally) with one
  command: `river_cli skill` (`--global`, `--force`, `--print`). The skill
  teaches AI coding assistants the river_cli workflow — scaffold with the CLI,
  compose with the widget library, style with the design tokens.
- **New generators** — each accepts `--path`, `--force`, and `--dry-run`:
  - `create model:<name>` — immutable data class with `fromJson`/`toJson`/
    `copyWith`/`toString`, generated from a **field spec**
    (`--fields "title:String, done:bool, due:DateTime?, tags:List<String>"`).
    Handles nullables, `DateTime` (ISO-8601), and `List<T>` casting.
  - `create repository:<name>` — repository wired to the Dio `BaseRepository`
    pattern when the `network` module is installed, or a compiling stub when
    it isn't.
  - `create widget:<name>` — reusable widget in `lib/app/shared_widgets/`,
    following the library's naming style.
  - `create feature:<name>` — the full CRUD bundle: model + repository +
    `AsyncNotifier` controller + list view + registered route, all wired
    together.
- **Convention-aware output**: generators detect which modules are installed
  and adapt — views use `MyText`/`AppErrorBanner`/`EmptyStateWidget`/
  `CustomLoadingSpinner`/`AppRefreshIndicator` and repositories use
  `BaseRepository` only when those modules are present, falling back to plain
  Material/stubs otherwise. Cross-file references use package imports, so
  generated code is correct regardless of `--path`.
- **`river_cli doctor`**: one-shot health check — SDK on PATH, project
  metadata, installed modules, core dependencies, routing, scaffolded
  features, and whether the Claude Code skill is installed.
- **Safer generation**: `--dry-run` previews every file without writing;
  existing files are skipped unless `--force`; routes are de-duplicated.
- Added `version`/`--version` and `help`/`--help` commands.

## 1.1.0

- **Modular `init`**: `river_cli init` now scaffolds a curated set of reusable
  `lib/` building blocks organized into opt-in modules — `config` (colors, text
  styles, constants, strings, globals, environment switch, local keys), `utils`
  (formatting, toasts, validators, keyboard helpers), `extensions`, `widgets`
  (text, button, container, input field, asset image, refresh indicator, error
  banner, empty state, loading spinner), `network` (Dio client, request
  abstraction, typed exceptions, endpoints, repository base), and `storage`
  (SharedPreferences wrapper + secure storage). `core` (entry point, routing,
  sample home feature) is always generated.
- **Customizable**: choose modules interactively, or with flags — `--all`,
  `--minimal`, `--modules a,b,c`, `--yes` (non-interactive), `--force`
  (overwrite), `--no-pub-get`, `--list`, `--help`.
- **Safe re-runs**: existing files are skipped by default (use `--force` to
  overwrite); a summary reports created/overwritten/skipped files.
- **Smart package management**: only the selected modules' packages are added,
  via `flutter pub add` so versions resolve compatibly with the project's
  Dart/Flutter SDK. Falls back to unversioned pubspec entries when Flutter is
  not on PATH. Dependent modules are pulled in automatically.
- **Modern Riverpod API**: generated controllers/providers now use
  `Notifier` / `NotifierProvider` (compatible with Riverpod 2.x and 3.x),
  replacing the removed `StateNotifier` API.
- Bumped the CLI's own SDK constraint and dependencies for the latest Dart.

## 1.0.6

- Class names for generated pages are now always in CamelCase, even if the user provides snake_case. Only folder and file names remain in snake_case. This ensures Dart best practices for class naming.
- 'Change headline4 to headlineMedium

## 1.0.3

- Initial release of `river_cli`.
- Added support for `river_cli init` to initialize the project structure with folders and base configuration.
- Added `river_cli create page:<page_name>` command to generate a feature structure with:
  - `controllers`
  - `bindings`
  - `views`
- Integrated automatic route updates for `go_router`, including route imports and configuration.
- Enhanced feature creation with customizable paths via the `--path` flag.
- Ensured compatibility with Flutter projects using Riverpod and GoRouter.
- Introduced a user-friendly CLI interface to streamline Flutter development workflows.

