
# Riverpod CLI

A command-line tool to automate the creation of a feature structure in a Flutter project using the Riverpod state management package. This tool helps you generate necessary folders and files for each feature (such as controllers, bindings, and views) and integrates the new feature with your app's routing system using `go_router`.

## Features

- **Scaffold a Modular Project Structure**: Initialize your project with `river_cli init` and opt into reusable modules (config, utils, extensions, widgets, networking, storage) — only the files and packages you pick are added.
- **Generate Page Feature**: Easily create a new feature page with a controller, binding, and view using `river_cli create page:<page_name>`.
- **Generate Full CRUD Features from a field spec**: `river_cli create feature:<name> --fields "title:String, done:bool"` scaffolds a model, repository, `AsyncNotifier` controller, list view, and route — all wired together.
- **Generate Models, Repositories & Widgets**: `create model:`, `create repository:`, and `create widget:` generate idiomatic, ready-to-use building blocks.
- **Convention-aware output**: generated code automatically uses your widget library (`MyText`, `AppErrorBanner`, …) and the networking `BaseRepository` pattern when those modules are installed — and falls back gracefully when they aren't.
- **Integrate with GoRouter**: Adds new pages/features as routes in the `GoRouter` configuration, along with the corresponding import.
- **Support for Riverpod**: Integrates the Riverpod controller into each feature.
- **Claude Code skill**: `river_cli skill` installs an AI skill so assistants like Claude Code follow the river_cli workflow automatically.
- **Doctor**: `river_cli doctor` health-checks your project, modules, dependencies, and setup.

## AI-assisted development (Claude Code skill)

river_cli ships with a [Claude Code](https://claude.com/claude-code) **skill**
that teaches AI coding assistants the river_cli workflow — *scaffold with the
CLI, compose with the widget library, style with the design tokens, never
hand-roll the three*. Install it into your project (or globally) with one
command:

```bash
river_cli skill            # installs ./.claude/skills/river-cli-flutter/SKILL.md
river_cli skill --global   # installs ~/.claude/skills (all projects)
river_cli skill --print    # print the skill to stdout
```

Once installed, when you ask Claude Code to "create a profile screen" or
"implement this Figma design", it will use `river_cli create …`, reuse your
shared widgets, and stick to your design tokens — instead of generating
ad-hoc Material code.

## Installation

### 1. Install CLI

Ensure you have Dart and Flutter installed. Navigate to the project folder and run:

```bash
dart pub global activate river_cli
```


### 2. Run the CLI

Once everything is set up, you can use the following commands.


## Commands

### 1. `Initialize a Modular Project Structure`

`init` scaffolds commonly-used `lib/` files, folders, and packages into your
Flutter project. The reusable code is grouped into **modules** that you opt into
— interactively or with flags. Only the selected modules' files and packages are
added, and existing files are **skipped** (never overwritten) unless you pass
`--force`. Packages are installed with `flutter pub add`, so versions are
resolved to match your project's Dart/Flutter SDK.

```bash
river_cli init            # interactive: prompts Yes/No per module
river_cli init --all      # everything
river_cli init --minimal  # just the core (entry point, routing, home feature)
river_cli init --modules config,utils,widgets
```

#### Available modules

| Module       | What it adds | Packages |
|--------------|--------------|----------|
| `core` *(always)* | `main.dart`, `go_router` routing, and a sample Riverpod home feature + the base `lib/` folder tree | `flutter_riverpod`, `riverpod`, `go_router` |
| `config`     | `AppColors` (with a runtime-swappable primary), `AppTextStyles`, `AppConstants`, `AppStrings`, `Globals` + `.env` loading, dev/prod `AppEnvironment`, `LocalDataKey` enum | `sizer`, `google_fonts`, `flutter_dotenv` |
| `utils`      | `Utils` (asset paths, date formatting, toasts, snackbars, URL launching), `Validators`, date helpers, keyboard helpers | `intl`, `fluttertoast`, `url_launcher` |
| `extensions` | `num.height` / `.width`, `Color.withOpacityValue`, `DateTime.weekOfYear` | — |
| `widgets`    | `MyText`, `CustomButton`, `MyContainer`, `InputTextField`, asset image/icon, refresh indicator, error banner, empty state, loading spinner | `google_fonts`, `sizer` |
| `network`    | Dio `APIProvider` (get/post/put/patch/delete/multipart, bearer auth, typed errors), `APIRequestRepresentable`, `ApiEndPoints`, exceptions, `BaseRepository` + sample | `dio` |
| `storage`    | `LocalDB` (typed SharedPreferences wrapper + Riverpod providers), `SecureStorageService` | `shared_preferences`, `flutter_secure_storage` |

Modules that depend on others pull them in automatically (e.g. `widgets`
requires `config`, `utils`, and `extensions`).

#### Init options

| Flag | Description |
|------|-------------|
| `-a`, `--all` | Include every optional module |
| `--minimal` | Only the core module |
| `-m`, `--modules <a,b,c>` | Include the listed modules (comma-separated) |
| `-y`, `--yes` | Non-interactive; with no selection, includes all modules |
| `-f`, `--force` | Overwrite files that already exist |
| `--no-pub-get` | Do not run `flutter pub add` / `pub get` |
| `-l`, `--list` | List available modules and exit |
| `-h`, `--help` | Show init help |

Run `river_cli init --list` to see the modules available in your installed version.

### 2. `Create Page`

This command generates the feature for a specific page, including the controller, binding, and view files, as well as updating the route configuration.

```bash
river_cli create page:<page_name> --path lib/features
```

OR

```bash
river_cli create page:<page_name>
```

For example, if you want to create a feature called `profile`, run:

```bash
river_cli create page:profile --path lib/features
```

OR

```bash
river_cli create page:profile
```

This will generate the following structure:

```
lib/features/profile/
  ├── controllers/profile_controller.dart
  ├── bindings/profile_binding.dart
  └── views/profile_view.dart
```

It will also add the appropriate route to the `GoRouter` configuration in `lib/routes.dart`.


### 3. `Create Screen Without Route Registration`

This command generates the feature for a specific page, including the controller, binding, and view files without route registration.

```bash
river_cli create screen:<page_name> --path lib/features
```

### 4. `Create a Full CRUD Feature`

`create feature:` is the fastest way to stand up a list/CRUD flow. From a field
spec it generates a **model**, **repository**, **`AsyncNotifier` controller**,
**list view**, and registers the **route** — all wired together.

```bash
river_cli create feature:product --fields "name:String, price:double, inStock:bool"
```

Generates:

```
lib/data/models/product_model.dart            # immutable data class
lib/data/repositories/product_repository.dart # CRUD repository (uses BaseRepository if network module present)
lib/presentation/product/
  ├── controllers/product_controller.dart      # AsyncNotifier<List<Product>>
  ├── bindings/product_binding.dart
  └── views/product_view.dart                  # list view with loading/error/empty states
```

…and adds the `product` route to your `go_router` config.

### 5. `Create Models, Repositories & Widgets`

```bash
# Immutable data class with fromJson/toJson/copyWith/toString from a field spec
river_cli create model:todo --fields "title:String, done:bool, due:DateTime?, tags:List<String>"

# …or infer the whole model (incl. nested models) from a JSON sample
river_cli create model:user --json '{"id":1,"name":"Ada","address":{"city":"X"},"orders":[{"ref":"A1"}]}'
river_cli create model:user --from-json sample.json

# Repository (extends BaseRepository + APIProvider when the network module is installed)
river_cli create repository:order

# Reusable widget in lib/app/shared_widgets/, following the library naming style
river_cli create widget:price_tag

# Generate a matching JSON round-trip test alongside the model/feature
river_cli create model:todo --fields "title:String, done:bool" --with-test
```

#### Generating models from JSON

`--json` / `--from-json` infer types from a sample payload: `int`, `double`,
`bool`, `String`, ISO-8601 strings as `DateTime`, typed `List<T>`, and **nested
objects and arrays-of-objects as their own generated models** (collection keys
are singularized, e.g. `orders` → `Order`). The example above generates `User`,
`Address`, and `Order` classes in one file, fully wired with recursive
`fromJson`/`toJson`.

#### The `--fields` spec

`--fields` takes comma-separated `name:Type` pairs. A trailing `?` marks the
field nullable. Supported types include `String`, `int`, `double`, `bool`,
`DateTime` (serialized as ISO-8601), and `List<T>`.

```
--fields "title:String, count:int, price:double, done:bool, due:DateTime?, tags:List<String>"
```

#### Common generator flags

| Flag | Description |
|------|-------------|
| `--path <dir>` | Output root for features/pages (default `lib/presentation`) |
| `--fields "<spec>"` | Field spec for `model:` / `feature:` |
| `--json "<json>"` | Infer a model from a JSON sample (`model:` / `feature:`) |
| `--from-json <file>` | Infer a model from a JSON file |
| `--with-test` | Also generate a JSON round-trip test |
| `-f`, `--force` | Overwrite files that already exist |
| `-n`, `--dry-run` | Preview the files that would be written without writing them |

### 6. `Doctor`

`river_cli doctor` runs a quick health check of your project — Flutter on PATH,
package metadata, which modules are installed, core dependencies, routing,
scaffolded features, and whether the Claude Code skill is installed.

```bash
river_cli doctor
```

### 7. `Regenerate Routes`

`generate routes` discovers every scaffolded feature (under `lib/presentation`
and `lib/features`) and rebuilds `lib/app/routes/app_routes.dart` and
`route_page.dart` from scratch, so the route table always matches what's on
disk. A `home` feature is wired to its view; otherwise `/` shows a
`Placeholder`. Use `--dry-run` to preview.

```bash
river_cli generate routes
```

> ⚠️ This overwrites the routing files — custom guards/redirects/nested routes
> are not preserved. Use it as a repair/sync command.

### 8. `Remove a Feature`

`remove` deletes a scaffolded feature and surgically unregisters its route
(constant + `GoRoute` block + import) while leaving the rest of the routing
file untouched. For `feature:` it also removes the generated model and
repository (`--keep-data` to keep them). It confirms before deleting.

```bash
river_cli remove feature:product          # prompts for confirmation
river_cli remove page:login --yes         # skip the prompt
river_cli remove feature:order --keep-data --dry-run
```

## Example

Running the command for `profile` will generate the following:

### 1. Files

- `lib/features/profile/controllers/profile_controller.dart`
- `lib/features/profile/bindings/profile_binding.dart`
- `lib/features/profile/views/profile_view.dart`


## License

This project is licensed under the MIT License.

---

### **Note:**  
This is a basic CLI tool to help automate the process of adding new features to your app with Riverpod. You can further extend and modify it according to your project's requirements.

---

## Developers

- [Tariq Malik](https://github.com/tariqarbi03)
- [Ahtsham Mehboob](https://github.com/Ahtsham0715)

