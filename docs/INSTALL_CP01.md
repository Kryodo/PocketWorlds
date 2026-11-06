# Applying CP01 to the local PocketWorlds project

This package is an overlay for the existing Godot project, not a replacement repository.

1. Make sure the current local project is committed in GitHub Desktop (the initial project commit is sufficient).
2. Extract the ZIP directly into the existing local `PocketWorlds` project root.
3. Merge directories when Windows asks. Replace `project.godot` when prompted.
4. Do not delete or replace `.git`, `.gitignore`, `.gitattributes`, `.editorconfig`, `icon.svg` or `icon.svg.import`.
5. Open the local project in Godot 4.7. Wait for the editor to scan the new scripts and scenes.
6. Run the project. The configured main scene is `res://scenes/app/main.tscn`.
7. After local verification, inspect the changed files in GitHub Desktop and commit them with a message such as `Add CP01 playable skeleton`.

The source package does not include `.git/` or `.godot/`. It does overwrite the existing `project.godot` to configure the main scene, the `GameState` autoload and portrait-first layout while preserving the starter project's Godot 4.7 Mobile renderer settings.

## If the project does not start

Do not continue editing blindly. Copy the first parser/import/runtime error from Godot's Output panel (including the script path and line number) and share it. This package was reviewed statically, but no Godot executable was available in the preparation environment, so it has not been runtime-validated here.
