# Project state

## Comparison baseline

The baseline is a stock Fedora KDE desktop session where Steam and Gamescope are launched and exited
manually. This project intends a reversible SteamOS-like session choice that enters fullscreen Steam
Gamepad UI, logs the run, returns cleanly to Plasma, and can be completely uninstalled.

## Current focus

S004 is the current focus.

## Capability inventory

| ID | Capability or outcome | State | Factual dependency | Goals |
| --- | --- | --- | --- | --- |
| S001 | Installation adds a Wayland session picker and Plasma shortcut for entering game mode | partial | — | G001 |
| S002 | The selected session launches Steam Gamepad UI under fullscreen Gamescope and logs the run | partial | S001 | G001 |
| S003 | Returning to desktop logs out through an available KDE or system session command | partial | S002 | G001 |
| S004 | Installation and removal are documented, validated, and tested without leaving user files behind | missing | S001 | G001 |

## Capability details

### S001 — User installation

The installer creates the session entry, per-user selector, and desktop shortcut described by the
shipping scripts.

Gap: the repository has no automated positive/negative install verification or user documentation.

### S002 — Gamescope Steam session

The generated session selects Steam Gamepad UI, launches it through Gamescope with the configured
composition/HDR/cursor options, and writes logs below the user state directory.

Gap: behavior has no recorded verification against current Fedora KDE, Gamescope, and Steam releases.

### S003 — Desktop return

The scripts attempt KDE DBus logout tools before the system session fallback and provide Steam's return
to desktop command.

Gap: each supported logout route and its failure behavior is untested.

### S004 — Complete lifecycle verification

Missing capability: the project lacks a README, dependency checks, a non-destructive test harness, and a
verified install/uninstall round trip proving no stale files or selection flags remain.
