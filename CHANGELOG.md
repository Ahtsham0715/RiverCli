

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

