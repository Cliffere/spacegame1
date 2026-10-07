# Space Ship Game

A tiny Godot 4 arcade prototype with a plain white UI.

> **A-D to move up or down. Avoid the blocks**

## Run locally

1. Install **Godot 4.7 or newer**.
2. Clone or download this repository.
3. Open `project.godot` in Godot.
4. Press **F6** or **F5** to run the game.

## Controls

- **A** — move up
- **D** — move down
- **Enter** or **Space** — start/restart
- **UP / DOWN** buttons — touch-friendly controls

## Project structure

- `project.godot` — Godot project configuration
- `scenes/main.tscn` — main scene
- `scripts/neon_nibble.gd` — game loop, drawing, controls, and UI
- `assets/fonts/` — bundled Comic Neue font and license
- `test/` — lightweight source checks

## Font

The project uses **Comic Neue**, an open-source Comic Sans-style font bundled in `assets/fonts/`. Its SIL Open Font License is included beside the font files.

## Web export

Install the Godot Web export templates, then create a Web preset in Godot and export to a folder such as `dist/`. The game itself has no backend or external service dependency.

## Deploy to GitHub Pages

This repository includes `.github/workflows/deploy-pages.yml`. After you push the project to GitHub:

1. Open **Settings → Pages** for the repository.
2. Set **Source** to **GitHub Actions**.
3. Push to the `main` branch, or run **Deploy Space Ship Game to GitHub Pages** from the Actions tab.

The workflow installs Godot 4.7.2, exports the `Web` preset, and publishes the generated `dist/` folder. The game will be available at:

`https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/`
