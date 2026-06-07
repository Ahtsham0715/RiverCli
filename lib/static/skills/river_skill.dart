/// The bundled Claude Code skill, embedded as a string so `river_cli skill`
/// can write it into a project regardless of how the CLI was installed.
///
/// Keep this in sync with the documentation in README.md.
const String kSkillFileName = 'SKILL.md';

const String kRiverSkillContent = r'''
---
name: river-cli-flutter
description: Build Flutter features using the river_cli scaffolding tool and the project's reusable widget library. ALWAYS use this skill when working in a Flutter project that uses river_cli, Riverpod, or go_router — including when the user asks to create a new screen, page, feature, model, repository, widget, or flow; implement a Figma design; add UI; or refactor features. Use it even if the user doesn't mention river_cli by name. Never manually create feature folders, controllers, models, or routes in these projects — this skill defines the required workflow.
---

# river_cli Flutter Development

This skill defines how to build features in Flutter projects scaffolded with
[river_cli](https://pub.dev/packages/river_cli) (Riverpod + go_router, modular
`lib/` structure with reusable widgets, networking, and storage modules).

**Golden rule: scaffold with the CLI, compose with the widget library, style
with the design tokens. Never hand-roll any of the three.**

## 1. Detect the project setup

Before writing code, run the built-in health check — it reports the package
name, which modules are installed, missing dependencies, and scaffolded
features in one shot:

```bash
river_cli doctor
```

If `doctor` reports a brand-new/empty project, initialize it first (ask the
user which modules they want if unclear):

```bash
dart pub global activate river_cli   # if not installed
river_cli init --all                 # or --minimal, or --modules config,utils,widgets
```

Available modules: `core` (always), `config`, `utils`, `extensions`,
`widgets`, `network`, `storage`. Existing files are never overwritten unless
`--force` is passed — do not pass `--force` without explicit user permission.

## 2. Creating things — ALWAYS use the CLI

Every generator accepts `--path <dir>` (default `lib/presentation`),
`--force` (overwrite), and `--dry-run` (preview without writing). Prefer
`--dry-run` first when you are unsure what will be generated.

```bash
# Page with automatic go_router route registration
river_cli create page:<snake_case_name>

# Screen WITHOUT route registration (tabs, bottom-sheet content, sub-views)
river_cli create screen:<snake_case_name>

# Immutable data model with fromJson/toJson/copyWith, generated FROM A FIELD SPEC
river_cli create model:<name> --fields "title:String, done:bool, age:int?"

# …or infer the model (incl. nested models) from a JSON sample
river_cli create model:<name> --json '{"id":1,"name":"x","address":{"city":"y"}}'

# Repository wired to the network BaseRepository pattern
river_cli create repository:<name>

# Reusable widget placed in lib/app/shared_widgets/ following the library style
river_cli create widget:<name>

# FULL CRUD feature: model + repository + AsyncNotifier controller + view + route
river_cli create feature:<name> --fields "title:String, done:bool"
```

The `--fields` spec is `name:Type` pairs separated by commas; a trailing `?`
marks a field nullable (`age:int?`). Supported types include `String`, `int`,
`double`, `bool`, `DateTime`, and `List<T>`. Use it whenever the user describes
the shape of the data — do not hand-write model boilerplate. When the user
provides a JSON payload (or an API response), prefer `--json`/`--from-json` to
infer the model and any nested models. Add `--with-test` to also emit a
round-trip test.

Maintenance commands:

```bash
river_cli generate routes              # rebuild lib/app/routes/ from features on disk
river_cli remove feature:<name>        # delete a feature + its model/repo + route
```

`generate routes` overwrites the routing files (no custom guards preserved) —
use it to repair/sync. `remove` confirms before deleting; pass `--yes` to skip.

`page:` / `screen:` / `feature:` generate:

```
lib/<path>/<name>/
  ├── controllers/<name>_controller.dart   # Riverpod controller
  ├── bindings/<name>_binding.dart
  └── views/<name>_view.dart
```

After scaffolding:
- Put ALL state and business logic in the controller. Views stay declarative
  and read state via `ref.watch`.
- Do not move, rename, or restructure the generated folders.
- The CLI registers routes for `page:`/`feature:` automatically — do not edit
  the routing files manually except for guards, redirects, or nested routes.

## 3. UI composition — use the widget library, never raw Material

When the `widgets` module is present, these components exist and MUST be used
instead of their Material equivalents:

| Use this            | Instead of                          |
| ------------------- | ----------------------------------- |
| `MyText`            | `Text`                              |
| `CustomButton`      | `ElevatedButton` / `TextButton`     |
| `MyContainer`       | `Container` (for styled boxes)      |
| `InputTextField`    | `TextField` / `TextFormField`       |
| `CustomAssetImage` / `CustomAssetIcon` | `Image.asset` / `Icon` |
| `AppRefreshIndicator` | `RefreshIndicator`                |
| `AppErrorBanner` / `EmptyStateWidget` / `CustomLoadingSpinner` | ad-hoc error/empty/loading UI |

Before building ANY new widget, run `river_cli create widget:<name>` or list
`lib/app/shared_widgets/` and reuse what is there. Only create a new shared
widget if nothing fits, and follow the naming style of the existing files.

## 4. Styling — design tokens only

When the `config` module is present:

- Colors: `AppColors.*` only. Never hardcode `Color(0xFF...)` or `Colors.*`.
  The primary color is runtime-swappable — assume it can change.
- Text styles: `AppTextStyles.*` only.
- Strings shown to users: `AppStrings.*` (add new constants there).
- Constants/keys: `AppConstants`, `LocalDataKey` enum for local storage keys.
- Sizing: the project uses `sizer` — use responsive units and the `num.height`
  / `num.width` extensions rather than fixed pixel values where layout scales.
- Environment values come from `AppEnvironment` / `.env` via `Globals` —
  never hardcode URLs, API keys, or environment-specific values.

## 5. Networking and storage

- All HTTP goes through the Dio `APIProvider` + `APIRequestRepresentable` +
  repository pattern (`BaseRepository`). Add endpoints to `ApiEndPoints`.
  Generate repositories with `river_cli create repository:<name>`. Never
  instantiate Dio or http clients directly in controllers or views.
- Errors from the network layer are typed — handle them with the provided
  exception types and surface them via `AppErrorBanner`.
- Local persistence: `LocalDB` (typed SharedPreferences wrapper with Riverpod
  providers) for non-sensitive data, `SecureStorageService` for tokens and
  secrets. Keys go in the `LocalDataKey` enum.

## 6. Figma-to-Flutter workflow

When implementing a Figma design (via the Figma MCP server or screenshots):

1. **Plan first, in plan mode if available.** List the screens in the flow,
   identify UI elements that repeat, and map each element to an existing
   `lib/app/shared_widgets/` component or propose a new shared widget. Present
   this component inventory to the user before generating code.
2. **Map design tokens.** Match Figma colors/text styles to `AppColors` /
   `AppTextStyles`. If a token is missing, add it to the config files.
3. **Model the data** behind each screen with `river_cli create model:` or a
   full `create feature:` when there is a backing list/CRUD flow.
4. **Scaffold every screen** with `river_cli create page:` (or `screen:`).
5. **Build shared widgets first**, then compose screens from them.
6. **Verify**: run `dart format .` and `dart analyze` and fix all issues.

## 7. Quality gates (run before finishing any task)

```bash
river_cli doctor   # confirm setup & dependencies
dart format .
dart analyze
flutter test       # if tests exist
```

Code that fails analysis is not done. If `analysis_options.yaml` defines
strict lints, satisfy them rather than suppressing with `// ignore`.

## 8. User style preferences

- Prefer small, single-purpose widgets over large build methods; extract
  widgets when a build method exceeds ~60 lines.
- No business logic in views — controllers only.
- Follow existing file naming exactly: `snake_case` files,
  `<feature>_controller.dart`, `<feature>_view.dart`.
''';
