# `bin/` — user-facing commands

Commands here are installed onto `PATH` (Ayaz's box symlinks them into
`~/.local/bin` via dotfiles' `scripts/deploy-bin`). They are invoked by the
user, by keybinds, or by systemd units — never by the running shell as part of
its own startup.

## Why this is not `scripts/`

`scripts/` is mirrored into the live Quickshell tree at
`~/.config/quickshell/inir/scripts/`, and dotfiles' `dotfiles-drift` compares
the two copies. Anything added to `scripts/` that the live shell does not also
have is reported as drift forever.

These nine commands were briefly placed in `scripts/` on 2026-07-24 and
immediately showed up as nine phantom drift entries. They are not shell runtime
code, so they belong outside the mirrored tree.

Rule of thumb:

- **`scripts/`** — code the Quickshell shell itself runs. Mirrored to the live
  shell tree.
- **`bin/`** — commands a human or a keybind runs. Deployed to `PATH`.

`scripts/inir` is the exception and stays put: the `Makefile`'s `install`
target references that path for system-wide installs.
