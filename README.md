# Desktop Notes for Omarchy

A desktop widget for notes and checklist items, built as an Omarchy shell plugin. It follows the active shell theme and supports English and Russian.

- Add and edit multiline notes and tasks.
- Check off tasks or remove individual entries.
- Changes are saved locally and automatically to `~/.local/state/omarchy/desktop-notes.json`.
- The widget appears in the upper-right corner of the first display, behind application windows.
- Toggle it with `omarchy-shell desktopNotes toggle`; a desktop hint shows the configured shortcut. The default hint assumes Super + Alt + N.

Add this line to `~/.config/hypr/bindings.lua` to set the shortcut, if it is free:

```lua
o.bind("SUPER + ALT + N", "Desktop notes", "omarchy-shell desktopNotes toggle")
```

## Installation

Create the data file before enabling the plugin. These commands preserve an existing file:

```sh
mkdir -p ~/.local/state/omarchy
if [ ! -e ~/.local/state/omarchy/desktop-notes.json ]; then
  (umask 077; printf '[]\n' > ~/.local/state/omarchy/desktop-notes.json)
fi
omarchy plugin add https://github.com/PolyakovYan11/omarchy-desktop-notes.git --enable
```

If the plugin is already installed, use `omarchy plugin enable local.desktop-notes` to enable it. Disable it with `omarchy plugin disable local.desktop-notes`. Disabling or removing the plugin does not remove the data file.

The widget requires an Omarchy version with the Quickshell plugin system. It does not synchronize data between devices.

## License

MIT. See [LICENSE](LICENSE).
