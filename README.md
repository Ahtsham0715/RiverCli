
# Riverpod CLI

A command-line tool to automate the creation of a feature structure in a Flutter project using the Riverpod state management package. This tool helps you generate necessary folders and files for each feature (such as controllers, bindings, and views) and integrates the new feature with your app's routing system using `go_router`.

## Features

- **Generate Project Structure**: Initialize your project with a base structure for managing features using `river_cli init`.
- **Generate Page Feature**: Easily create a new feature page with a controller, binding, and view using `river_cli create page:<page_name>`.
- **Generate Folder Structure**: Automatically creates folders like `controllers`, `bindings`, and `views` for each new feature.
- **Generate Files**: Creates the necessary Dart files with basic boilerplate code, including a controller, binding, and view.
- **Integrate with GoRouter**: Adds the new page as a route in the `GoRouter` configuration, along with the corresponding import.
- **Support for Riverpod**: Integrates the Riverpod controller into each feature.

## Installation

### 1. Install CLI

Ensure you have Dart and Flutter installed. Navigate to the project folder and run:

```bash
dart pub global activate river_cli
```


### 2. Run the CLI

Once everything is set up, you can use the following commands.


## Commands

### 1. `Initialize Fully Structured Project`

This command initializes the project structure by creating the necessary folders and configurations.

```bash
river_cli init
```

This will generate the following structure:

```
lib/features/
  ├── controllers/
  ├── bindings/
  └── views/
```

You can modify the generated structure as needed for your project.

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

