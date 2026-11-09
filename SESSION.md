# h0 building Window Opacity

Rendered from the session's recorded trace (`trace.jsonl`), not from a screen capture. Workspace paths are shown as `~`; tool output is cut to its first 40 lines.

Model `claude-opus-5-5` · fitting `omarchy-v4` · tools read, edit, write, grep, glob, bash, check

---

### › You

```text
Build me an Omarchy shell plugin that puts a window opacity control in my top bar. Clicking it should open a small panel with two sliders, one for the focused window and one for unfocused windows, that change Hyprland's opacity live. Keep my settings after a restart.
```

I'll start by reading the plugin guide and looking at the existing config.

**⏺ bash** `cat /usr/share/omarchy/default/agents/skills/omarchy/plugins.md; ls -la .config/omarchy .config/omarchy/plugins 2>&1; cat .config/omarchy/shell.json; ls $OMARCHY_PATH/shell/plugins/`

✓ 95 ms

```text
[exit 0, 88 ms]
# Omarchy Shell: Bar, Plugins, and Idle

Read this before changing the status bar, notifications, shell plugins,
widgets, or idle/lock behavior.

The bar, notification daemon, settings panel, and assorted overlays all run
inside a single long-running Quickshell process (`omarchy-shell`).

```
~/.config/omarchy/shell.json             # User overrides: bar, plugins, idle
~/.config/omarchy/plugins/<plugin-id>/   # User-owned shell plugins
$OMARCHY_PATH/config/omarchy/shell.json  # Canonical defaults
```

The shell hot-reloads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `omarchy restart shell`, `omarchy refresh shell`

## Bar Layout

Use the `omarchy bar` group to move and manage widgets:

```bash
omarchy bar move omarchy.clock --section right
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/omarchy/shell.json`; it hot-reloads on save.

## Customizing Built-In Plugins and Widgets

To customize a built-in bar widget, never edit `$OMARCHY_PATH/shell/plugins/`.
Clone it into the user plugin directory instead:

```bash
omarchy plugin clone omarchy.workspaces
# Edit ~/.config/omarchy/plugins/<username>.workspaces/; saved changes reload automatically.
```
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell/plugins; cat README.md; ls -R bar | head -80`

✓ 91 ms

```text
[exit 0, 85 ms]
# First-party plugins

These plugins ship with Omarchy and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`omarchy.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/omarchy/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `omarchy.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `omarchy.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `omarchy.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `omarchy.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `omarchy.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| Omarchy menu  | `omarchy.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `omarchy.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `omarchy.audio`           | `bar-widget`            | `panels/audio/Panel.qml`              |
| Bluetooth     | `omarchy.bluetooth`       | `bar-widget`            | `panels/bluetooth/Panel.qml`          |
| Clock         | `omarchy.clock`           | `bar-widget`            | `panels/clock/BarWidget.qml`          |
| Monitor       | `omarchy.monitor`         | `bar-widget`            | `panels/monitor/Panel.qml`            |
| Network       | `omarchy.network`         | `bar-widget`            | `panels/network/Panel.qml`            |
| Power         | `omarchy.power`           | `bar-widget`            | `panels/power/Panel.qml`              |
| Tailscale     | `omarchy.tailscale`       | `bar-widget`            | `panels/tailscale/Panel.qml`          |
| Agents   | `omarchy.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `omarchy.weather`         | `bar-widget`            | `panels/weather/BarWidget.qml`        |
| Media         | `omarchy.media`           | `service`, `bar-widget` | `services/media/Service.qml`, `services/media/BarWidget.qml` |
| Battery       | `omarchy.battery`         | `service`               | `services/battery/Service.qml`        |
| Idle          | `omarchy.idle`            | `service`               | `services/idle/Service.qml`           |
| Night light   | `omarchy.nightlight`      | `service`               | `services/nightlight/Service.qml`     |
| Lock screen   | `omarchy.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `omarchy.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `omarchy.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

…
```

Next I'll look at a stock panel widget that has a popup with a slider. The audio panel is the closest match.

**⏺ bash** `cd $OMARCHY_PATH/shell/plugins/panels; ls -R audio monitor; cat audio/manifest.json; wc -l audio/*.qml monitor/*.qml; cat ../bar/README.md | head -150`

✓ 96 ms

```text
[exit 0, 89 ms]
audio:
Model.js
Panel.qml
manifest.json

monitor:
Model.js
Panel.qml
manifest.json
{
  "schemaVersion": 1,
  "id": "omarchy.audio",
  "name": "Audio",
  "version": "1.0.0",
  "author": "Omarchy",
  "description": "Volume slider, output picker, per-app mixer",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "Panel.qml"
  },
  "barWidget": {
    "displayName": "Audio",
    "description": "Volume slider, output picker, per-app mixer",
    "category": "Audio",
    "allowMultiple": false
  }
}
 1248 audio/Panel.qml
  929 monitor/Panel.qml
 2177 total
# Omarchy bar

This is the Quickshell implementation of the Omarchy status bar. It is
shipped as a first-party plugin of [`omarchy-shell`](../../README.md), the
long-running shell host. The bar is mounted at startup and lives inside
the shell for its whole session.

…
```

**⏺ bash** `cd $OMARCHY_PATH/shell/plugins/panels; sed -n 150,400p ../bar/README.md; cat monitor/manifest.json`

✓ 72 ms

```text
[exit 0, 66 ms]
  }
}
```

## Bar properties available to widgets

Widgets receive `bar` (the shell root), `moduleName` (string), and `settings` (object) injected at load time. The bar exposes:

- `bar.foreground`, `bar.background`, `bar.urgent` — theme colors (live-updated)
- `bar.fontFamily` — current monospace family
- `bar.position` — `"top" | "bottom" | "left" | "right"`
- `bar.vertical` — boolean shortcut
- `bar.barSize` — 26 horizontal / 28 vertical
- `bar.run(command)` — fire-and-forget bash exec
- `bar.shellQuote(value)` — safe shell-quote a string
- `bar.showTooltip(target, text)` / `bar.hideTooltip(target)` — shared tooltip popup
- `bar.requestPopout(owner)` / `bar.releasePopout(owner)` — one-popup-at-a-time coordinator

First-party bar widgets are manifest-backed just like third-party widgets.
Simple widgets carry sibling manifests such as `widgets/Workspaces.manifest.json`;
richer popup plugins live in feature directories such as `../panels/audio/`,
`../panels/network/`, and `../agents/`; and feature plugins such as
`omarchy.menu` and `omarchy.media` declare their bar-widget entry points in their own
`manifest.json`. Bar layout ids are namespaced, e.g. `omarchy.audio`,
`omarchy.network`, and `omarchy.clock`. Older UpperCamelCase ids such as
`AudioPanel` and `Clock` are migrated forward; new configs should use the
namespaced ids.

Third-party widgets ship as separate plugins under
`~/.config/omarchy/plugins/<plugin-id>/` with their own `manifest.json`
declaring `kinds: ["bar-widget"]` and a `barWidget` entry point. See
[../../README.md](../../README.md) for the manifest schema. Rescan, enable,
and place third-party plugins with `omarchy-shell shell rescanPlugins`,
`omarchy plugin enable`, and `omarchy bar move`.
{
  "schemaVersion": 1,
  "id": "omarchy.monitor",
  "name": "Display",
  "version": "1.0.0",
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell/plugins/panels; cat monitor/Panel.qml`

✓ 82 ms

```text
[exit 0, 69 ms]
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "omarchy.monitor"
  ipcTarget: "omarchy.monitor"
  manageIpc: false

  // manageIpc: false so this panel can own the single IpcHandler the target
  // permits — needed for the brightness + state methods below.
  property int brightnessPercent: 0
  property int pendingBrightnessPercent: 0
  property bool brightnessSetQueued: false
  property bool brightnessAvailable: false
  property string internalMonitor: ""
  property string externalMonitor: ""
  property string focusedMonitor: ""
  property bool internalEnabled: false
  property bool mirrorEnabled: false
  property string monitorScale: ""
  property var displays: []
  property int enabledDisplayCount: 0

  // Carry sub-notch touchpad deltas between wheel events.
  property real wheelAccumulator: 0

  // Cursor model shared by keyboard and mouse. Sections:
  //   "brightness" - single slider row, selectedIndex = -1 sentinel
  //                  (mirrors Audio's slider rows). Only present if a
  //                  controllable backlight was detected.
  //   "scale"      - 6 Button scale presets; treated as a single
  //                  horizontal row from j/k's perspective. h/l moves
  //                  between presets, identical to bluetooth's header.
…
```

The middle of that file was cut off. I need the panel skeleton, the bar button and the slider markup from it.

**⏺ bash** `cd $OMARCHY_PATH/shell/plugins/panels; grep -n "" monitor/Panel.qml | sed -n 300,640p`

✓ 74 ms

```text
[exit 0, 66 ms]
300:    if (!name) return
301:    if (enabled && root.enabledDisplayCount <= 1) return
302:
303:    actionProc.command = ["hyprctl", "keyword", "monitor", name + (enabled ? ",disable" : ",preferred,auto,auto")]
304:    if (!actionProc.running) actionProc.running = true
305:  }
306:
307:  function setScale(scale) {
308:    actionProc.command = ["bash", "-c", "omarchy-hyprland-monitor-scaling " + scale]
309:    if (!actionProc.running) actionProc.running = true
310:  }
311:
312:  // ---- Text size (shell base font + GTK text-scaling, via one CLI) ----
313:  function nearestTextStop(px) {
314:    var best = 0
315:    var bestDist = 1e9
316:    for (var i = 0; i < textSizeStops.length; i++) {
317:      var d = Math.abs(textSizeStops[i] - px)
318:      if (d < bestDist) { bestDist = d; best = i }
319:    }
320:    return best
321:  }
322:
323:  // Effective stop index: the pending choice while a change is in flight,
324:  // otherwise whatever Style's live base-size rounds to.
325:  function currentTextIndex() {
326:    return textSizePreviewIndex >= 0 ? textSizePreviewIndex : nearestTextStop(Style.font.baseSize)
327:  }
328:
329:  // px shown in the header: the pending stop if any, else the true base-size
330:  // (which may be an off-notch value set from the CLI).
331:  function displayedTextPx() {
332:    return textSizePreviewIndex >= 0 ? textSizeStops[textSizePreviewIndex] : Style.font.baseSize
333:  }
334:
335:  function setTextSize(px) {
336:    textScaleProc.command = ["omarchy-display-text-size", String(px)]
337:    if (!textScaleProc.running) textScaleProc.running = true
338:  }
…
```

Now the shared UI components (`Panel`, `PanelSlider`) and the shell README, which should have the manifest schema and any per-plugin settings storage.

**⏺ bash** `cd $OMARCHY_PATH/shell; ls; ls Ui Commons 2>/dev/null; grep -n -i -E "settings|persist|state|qs\.|manifest|schema" README.md | head -80`

✓ 71 ms

```text
[exit 0, 66 ms]
Commons
README.md
Ui
plugins
services
shell.qml
Commons:
Border.qml
BorderGeometry.js
Color.qml
Style.qml
Util.qml
qmldir

Ui:
BarIconButton.qml
BarIndicator.qml
BarWidget.qml
BorderOverlay.qml
BorderSurface.qml
Button.qml
ButtonGroup.qml
ConfirmDialog.qml
CursorSurface.qml
Dropdown.qml
KeyboardPanel.qml
MultiSelect.qml
NumberField.qml
OpticalGlyph.qml
Panel.qml
PanelActionButton.qml
PanelController.qml
PanelHero.qml
PanelKeyCatcher.qml
PanelSectionHeader.qml
PanelSeparator.qml
PanelSlider.qml
PanelToolTip.qml
PluginBarApi.qml
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell; sed -n 40,290p README.md`

✓ 77 ms

```text
[exit 0, 68 ms]
    osd/
    polkit/
```

The plugin discovery path is documented in [plugins/README.md](plugins/README.md).

## Plugin manifest

Every plugin ships a `manifest.json` describing what it is and how the
shell should load it. Minimal example:

```json
{
  "schemaVersion": 1,
  "id": "my.org.cool-clock",
  "name": "Cool clock",
  "version": "1.0.0",
  "author": "You",
  "description": "A clock that does cool things",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "Widget.qml" },
  "barWidget": {
    "displayName": "Cool clock",
    "category": "Time",
    "allowMultiple": false,
    "defaultSection": "left",
    "defaults": { "format": "HH:mm" },
    "schema": [
      { "key": "format", "type": "string", "label": "Format" }
    ]
  }
}
```

Supported `kinds`:

| Kind         | What it is                                                   |
|--------------|--------------------------------------------------------------|
| `bar-widget` | A component that the active bar can drop into a section      |
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell; cat Ui/PluginBarApi.qml | head -150; grep -rn -E "setSetting|updateSetting|saveSetting|setWidgetSetting|persistSetting" --include=*.qml . | head -30`

✓ 72 ms

```text
[exit 0, 67 ms]
import QtQuick

// Bar surface exposed to an installed third-party widget. Scalar presentation
// state is mirrored by Bar.qml and operations are delegated through scoped
// callbacks. The facade avoids direct host-Bar injection; it cannot isolate a
// visual child from the parent hierarchy of the QML scene that renders it.
QtObject {
  id: api

  required property string pluginId
  required property string moduleName
  property var shell: null

  property color foreground: "transparent"
  property color barForeground: "transparent"
  property color background: "transparent"
  property color urgent: "transparent"
  property string fontFamily: ""
  property string position: "top"
  property bool vertical: false
  property int barSize: 0
  property bool transparent: false
  property bool foregroundAnimationEnabled: true
  property bool centerSectionRevealHeld: false
  property bool _centerHoverRevealSuppressed: false
  readonly property bool centerHoverRevealSuppressed: _centerHoverRevealSuppressed
  property var activePopout: null
  property var clickTargets: []
  property var layoutConfig: ({})
  readonly property var foreignPopoutMarker: ({ foreign: true })

  property var _showTooltip: null
  property var _hideTooltip: null
  property var _registerClickTarget: null
  property var _unregisterClickTarget: null
  property var _requestPopout: null
  property var _releasePopout: null
  property var _switchPanelFrom: null
  property var _targetBelongsToWindow: null
…
```

**⏺ bash** `cd $OMARCHY_PATH; grep -rn -i "opacity" default/hypr/*.lua | head -30; grep -rln "hyprctl keyword\|hyprctl eval\|hl.config" bin | head; `

✓ 72 ms

```text
[exit 0, 66 ms]
default/hypr/windows.lua:5:-- Tag all windows for default opacity (apps can override with -default-opacity tag).
default/hypr/windows.lua:6:o.window(".*", { tag = "+default-opacity" })
default/hypr/windows.lua:21:-- App-specific tweaks (may remove default-opacity tag).
default/hypr/windows.lua:24:-- Apply default opacity after apps have had a chance to opt out.
default/hypr/windows.lua:25:o.window({ tag = "default-opacity" }, { opacity = "0.985 0.96" })
```

**⏺ bash** `cd $OMARCHY_PATH; sed -n 140,175p shell/plugins/panels/clock/Panel.qml; sed -n 1,80p shell/services/PluginShellApi.qml; sed -n 640,740p shell/shell.qml`

✓ 74 ms

```text
[exit 0, 67 ms]
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  function moveYear(delta) {
    moveMonth(delta * 12)
  }

  // Applied locally first so the panel redraws on the click itself; the
  // shell.json write comes back through the bar as the same value. With no
  // writable entry (the widget is not in the layout) it stays a session-only
  // preference rather than doing nothing. The host widget builds its own
  // entry when the label format is cycled, so it has to be kept in step or
  // it would write this key straight back out from a stale copy.
  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setWeekStart(day) {
    var next = Model.normalizedWeekStart(day, root.weekStart)
    if (next === root.weekStart) return
    persistSettings({ weekStartDay: Model.weekStartSettingName(next) })
  }

  function startEditingLife() {
    root.editingLife = true
    Qt.callLater(function() {
      bornField.text = root.birthYear > 0 ? String(root.birthYear) : ""
      expectancyField.text = String(root.lifeExpectancy)
import QtQuick

// Capability-scoped shell surface for installed third-party plugins.
…
```

**⏺ bash** `cd $OMARCHY_PATH; grep -rn "hyprctl" bin | grep -v "^.*#" | grep -E "keyword|eval|--batch" | head -20; ls bin | grep -i -E "toggle|gaps|opac|transpar" `

✓ 72 ms

```text
[exit 0, 66 ms]
omarchy-hyprland-toggle
omarchy-hyprland-toggle-disabled
omarchy-hyprland-toggle-enabled
omarchy-hyprland-window-gaps-toggle
omarchy-hyprland-window-single-square-aspect-toggle
omarchy-hyprland-window-tiled-fullscreen-toggle
omarchy-hyprland-window-transparency-toggle
omarchy-hyprland-workspace-layout-toggle
omarchy-toggle
omarchy-toggle-bar
omarchy-toggle-crash-capture
omarchy-toggle-enabled
omarchy-toggle-hybrid-gpu
omarchy-toggle-idle
omarchy-toggle-input-device
omarchy-toggle-nightlight
omarchy-toggle-notification-silencing
omarchy-toggle-screensaver
omarchy-toggle-suspend
omarchy-toggle-touchpad
omarchy-toggle-touchscreen
```

**⏺ bash** `cd $OMARCHY_PATH/bin; cat omarchy-hyprland-window-transparency-toggle omarchy-hyprland-window-gaps-toggle omarchy-hyprland-toggle`

✓ 73 ms

```text
[exit 0, 65 ms]
#!/bin/bash

# omarchy:summary=Toggles transparency for the currently focused window.

addr=$(hyprctl activewindow -j | jq -r '.address')
hyprctl dispatch "hl.dsp.window.set_prop({ window = \"address:$addr\", prop = \"opaque\", value = \"toggle\" })" >/dev/null 2>&1 || \
  hyprctl dispatch setprop "address:$addr" opaque toggle
#!/bin/bash

# omarchy:summary=Toggles the window gaps globally between no gaps and the default.

omarchy-hyprland-toggle window-no-gaps
#!/bin/bash

# omarchy:summary=Toggle permanent Hyprland flags by copying them into a directory that's sourced entirely.
# omarchy:args=<flag-name> [on|off|toggle]

usage() {
  echo "Usage: omarchy-hyprland-toggle <flag-name> [on|off|toggle]" >&2
}

if (($# < 1)); then
  usage
  exit 1
fi

FLAG_NAME="$1"
ACTION="${2:-toggle}"
FLAG_FILE="$HOME/.local/state/omarchy/toggles/hypr/$FLAG_NAME.lua"
FLAG_SOURCE="$OMARCHY_PATH/default/hypr/toggles/$FLAG_NAME.lua"

on() {
  if [[ -f $FLAG_SOURCE ]]; then
    mkdir -p "$(dirname "$FLAG_FILE")"
    cp "$FLAG_SOURCE" "$FLAG_FILE"
  else
    echo "Flag not found: $FLAG_NAME" >&2
    exit 1
  fi
…
```

Omarchy's own toggles write a Lua file and run `hyprctl reload`. I'll check what those files contain and whether any command changes an option live.

**⏺ bash** `cd $OMARCHY_PATH; ls default/hypr/toggles; cat default/hypr/toggles/window-no-gaps.lua; grep -rn -E "hyprctl (eval|keyword)" bin default shell 2>/dev/null | head -20; grep -rn "toggles" default/hypr/*.lua | head; cat ~/.config/hypr/hyprland.lua ~/.config/hypr/looknfeel.lua`

✓ 94 ms

```text
[exit 0, 87 ms]
flags.lua
single-window-aspect-ratio.lua
window-no-gaps.lua
-- Remove all window gaps and borders.
hl.config({
  general = {
    gaps_out = 0,
    gaps_in = 0,
    border_size = 0,
  },

  decoration = {
    rounding = 0,
  },
})
default/hypr/disabled-input-device.lua:10:  local file = io.open(paths.home .. "/.local/state/omarchy/toggles/hypr/" .. kind .. "-disabled-name", "r")
default/hypr/require_all.lua:3:-- default/hypr/bindings, and ~/.local/state/omarchy/toggles/hypr.
default/hypr/toggles.lua:4:local toggles_dir = paths.state_home .. "/omarchy/toggles/hypr"
default/hypr/toggles.lua:5:package.path = toggles_dir .. "/?.lua;" .. package.path
default/hypr/toggles.lua:11:require_all.files(toggles_dir, nil, {
-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
…
```

`omarchy-hyprland-window-transparency-toggle` hands a Lua expression to `hyprctl dispatch`. I'll look for any documented way to set a config option live under Lua.

**⏺ bash** `cd $OMARCHY_PATH; grep -n -i -E "hyprctl|keyword|eval|live|runtime" default/agents/skills/omarchy/hyprland.md | head -40; which hyprctl Hyprland quickshell luac 2>&1; grep -rn -E "hyprctl (dispatch|eval) .*hl\.(config|eval)" bin shell default 2>/dev/null | head`

✓ 134 ms

```text
[exit 0, 129 ms]
23:- Use `hyprctl reload` to force reload
24:- After ANY Hyprland Lua config change, validate with `hyprctl reload` followed by `hyprctl configerrors`
25:- If `hyprctl configerrors` reports errors, address them and rerun validation until clean or until a real blocker is identified
28:The two `.conf` files are read by separate processes, so `hyprctl` neither
67:List monitors and supported modes: `hyprctl monitors all`
/usr/bin/hyprctl
/usr/bin/Hyprland
/usr/bin/quickshell
/usr/bin/luac
```

**⏺ bash** `hyprctl --help 2>&1 | head -60; cat $OMARCHY_PATH/default/agents/skills/omarchy/hyprland.md | sed -n 1,60p`

✓ 92 ms

```text
[exit 0, 86 ms]
usage: hyprctl [flags] <command> [args...|--help]

commands:
    activewindow        → Gets the active window name and its properties
    activeworkspace     → Gets the active workspace and its properties
    animations          → Gets the current config'd info about animations
                          and beziers
    binds               → Lists all registered binds
    clients             → Lists all windows with their properties
    configerrors        → Lists all current config parsing errors
    cursorpos           → Gets the current cursor position in global layout
                          coordinates
    decorations <window_regex> → Lists all decorations and their info
    devices             → Lists all connected keyboards and mice
    dismissnotify [amount] → Dismisses all or up to AMOUNT notifications
    dispatch <dispatcher> [args] → Issue a dispatch to call a keybind
                          dispatcher with arguments
    eval <code>         → Issue a Lua string to execute
    getoption <option>  → Gets the config option status (values)
    globalshortcuts     → Lists all global shortcuts
    hyprpaper ...       → Issue a hyprpaper request
    hyprsunset ...      → Issue a hyprsunset request
    instances           → Lists all running instances of Hyprland with
                          their info
    keyword <name> <value> → Issue a keyword to call a config keyword
                          dynamically
    kill                → Issue a kill to get into a kill mode, where you can
                          kill an app by clicking on it. You can exit it
                          with ESCAPE
    layers              → Lists all the surface layers
    layouts             → Lists all layouts available (including plugin'd ones)
    monitors            → Lists active outputs with their properties,
                          'monitors all' lists active and inactive outputs
    notify ...          → Sends a notification using the built-in Hyprland
                          notification system
    output ...          → Allows you to add and remove fake outputs to your
                          preferred backend
    plugin ...          → Issue a plugin request
    reload [config-only] → Issue a reload to force reload the config. Pass
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell/Ui; cat Panel.qml PanelSlider.qml; sed -n 1,60p BarIconButton.qml; cat qmldir`

✓ 83 ms

```text
[exit 0, 68 ms]
import QtQuick
import Quickshell.Io
import qs.Commons

// Base item for plugin popup widgets. Many first-party plugins expose a bar
// button plus a popup from one QML entry point; this base owns the shared
// IPC-backed open/close lifecycle while implementations own button behavior,
// keyboard navigation, and content.
Item {
  id: root

  property QtObject bar: null
  property string moduleName: ""
  property var settings: ({})
  property string ipcTarget: ""
  property bool manageIpc: true
  property alias controller: panelController
  property bool popoutSwitching: false
  property bool popoutSwitchClosing: false

  readonly property bool opened: panelController.open
  readonly property color barForeground: bar ? bar.barForeground : Color.foreground

  function open() { panelController.show() }
  function close() { panelController.hide() }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { popoutSwitchClosing = false })
  }
  function toggle() { opened ? close() : open() }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function") return bar.switchPanelFrom(root, direction)
    return false
  }

  // Read a single value from this panel's inline shell.json entry, with a
  // fallback for missing/null values. Matches BarWidget.setting().
  function setting(name, fallback) {
…
```

**⏺ bash** `cd $OMARCHY_PATH/shell; sed -n 1,80p Ui/KeyboardPanel.qml; grep -rn "rawEvent\|configreloaded" --include=*.qml . | head; grep -rn "updateEntryInline" --include=*.qml plugins | head`

✓ 136 ms

```text
[exit 0, 128 ms]
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Layer-shell popup attached to a bar widget icon, designed for
// click-driven AND keyboard-driven panels (e.g. SUPER+CTRL+W summon).
//
// Built on PanelWindow with a brief WlrKeyboardFocus.Exclusive prime followed
// by OnDemand rather than PopupWindow (xdg-popup). The prime acquires focus
// both when the surface maps and when it reopens while still mapped for its
// fade-out. xdg-popups don't get that — they only receive keys after a
// click/hover routes focus through their parent surface — so keyboard-summoned
// popups fell flat without it.
//
// Exclusive would also grant map-time focus, but it makes Hyprland route
// *every* pointer event to the exclusive surface no matter which output
// the cursor is over, which leaves clicks on any other monitor unable to
// reach the dismissal surfaces below.
//
// API is a subset of Common.PopupCard: anchorItem, owner, bar, open,
// padding, margin, contentWidth/Height, centerOnBar, default contentItem.
// Missing on purpose (for now): triggerMode ("hover"), containsMouse.
//
// Positioning: full-screen layer-shell with the card placed inside at
// `cardOrigin`. We use the bar window's height/width for the perpendicular
// axis (away-from-bar) because mapToItem on the anchor returns
// bar-content-relative coords with internal layout offsets baked in
// (e.g. ~13px from the bar's vertical centering of its widget row). The
// parallel axis (along-the-bar) uses the anchor's content x/y since the
// bar spans full screen on that axis.
//
// Outside-click dismissal: an overlay MouseArea catches clicks, with the
// QsWindow.mask subtracting the bar strip so clicks on the bar still
// reach the bar widgets (activePopout coordinator hands off to another
// popup if the user clicks a different bar icon).
PanelWindow {
  id: root

…
```

**⏺ bash** `cd $OMARCHY_PATH/shell; sed -n 85,110p plugins/bar/widgets/KeyboardLayout.qml; grep -n "^import" plugins/bar/widgets/KeyboardLayout.qml; grep -n "updateEntryInline" -A30 shell.qml | grep -n "function updateEntryInline" -A30 | head -40`

✓ 99 ms

```text
[exit 0, 91 ms]
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      var name = String(event.name)
      // The event names the keyboard that switched ahead of the layout it moved
      // to, and that is the keyboard being typed on whatever holds the main flag.
      if (name === "activelayout") {
        const named = KeyboardLayoutModel.eventKeyboardName(event)
        if (named) root.typedKeyboardName = named
      }

      // A reload that adds a layout to kb_layout decides whether the widget
      // shows at all, and leaves every keyboard on the layout it was already
      // reading, so it raises no activelayout to notice it by.
      if (name.indexOf("activelayout") !== -1 || name === "configreloaded") root.refresh()
    }
  }

  Process {
    id: queryProc
    command: ["hyprctl", "-j", "devices"]
    onRunningChanged: {
      if (running) {
        stallTimer.restart()
        return
1:import QtQuick
2:import Quickshell
3:import Quickshell.Hyprland
4:import Quickshell.Io
5:import qs.Ui
6:import qs.Commons
7:import "KeyboardLayoutModel.js" as KeyboardLayoutModel
67:1078:  function updateEntryInline(moduleName, settings) {
68-1079-    var stripped = Util.canonicalWidgetId(moduleName)
69-1080-    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
70-1081-    if (!Util.isPlainObject(copy.bar)) copy.bar = { layout: { left: [], center: [], right: [] } }
71-1082-    if (!Util.isPlainObject(copy.bar.layout)) copy.bar.layout = { left: [], center: [], right: [] }
72-1083-    if (!Array.isArray(copy.plugins)) copy.plugins = []
…
```

Now the validator, so the manifest matches the schema the shell enforces.

**⏺ bash** `cat $(which omarchy-plugin-validate) | head -120; ls -a; ls .config`

✓ 96 ms

```text
[exit 0, 88 ms]
#!/bin/bash

# omarchy:summary=Validate a plugin folder against the Omarchy plugin manifest schema
# omarchy:group=plugin
# omarchy:args=<plugin-folder>
# omarchy:examples=omarchy plugin validate ./my-plugin

# Mirrors the checks in shell/services/PluginRegistry.qml so the CLI refuses to
# install anything the running shell would silently reject (or worse, load
# unsafely). The shell never trusts manifests blindly; neither do we.

set -o pipefail

fail() {
  echo "omarchy-plugin-validate: $*" >&2
  exit 1
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  cat <<USAGE
Usage: omarchy plugin validate <plugin-folder>

Checks a plugin folder's manifest.json against the schema the shell enforces:
schemaVersion, required fields, safe relative entry points that exist, an entry
point for each kind that needs one, no symlinks, and an id that is not reserved.
Exits 0 if valid — handy for plugin authors before publishing.
USAGE
  exit 0
fi

PLUGIN_DIR="${1:-}"
[[ -n $PLUGIN_DIR && -d $PLUGIN_DIR ]] || fail "plugin folder not found: ${PLUGIN_DIR:-<none>}"

MANIFEST="$PLUGIN_DIR/manifest.json"
[[ -f $MANIFEST ]] || fail "missing manifest.json in $PLUGIN_DIR"
jq -e . "$MANIFEST" >/dev/null 2>&1 || fail "manifest.json is not valid JSON: $MANIFEST"

# schemaVersion must be exactly the JSON number 1 (the only version the registry
# understands). jq's == is type-aware, so the string "1" is correctly rejected
…
```

Before writing the plugin I want to confirm two things: that third-party widgets get `bar.shell` (needed for `updateEntryInline`), and how `settings` is handed to them.

**⏺ bash** `cd $OMARCHY_PATH/shell; grep -n "PluginBarApi\|pluginBarApi\|shell: \|\"settings\"\|settings =" plugins/bar/Bar.qml | head -30`

✓ 71 ms

```text
[exit 0, 66 ms]
28:  property var shell: null
112:  property var pluginBarApis: ({})
116:    id: pluginBarApiComponent
117:    PluginBarApi { }
124:  function bindPluginBarApi(api) {
138:    root.syncPluginBarApiObjects(api)
141:  function syncPluginBarApiObjects(api) {
203:  function syncAllPluginBarApiObjects() {
204:    for (var id in pluginBarApis) root.syncPluginBarApiObjects(pluginBarApis[id])
229:  function pluginBarApiFor(pluginId, moduleName, registered) {
245:    if (pluginBarApis[key]) {
246:      pluginBarApis[key].shell = pluginShell
247:      return pluginBarApis[key]
250:    var api = pluginBarApiComponent.createObject(null, {
253:      shell: pluginShell,
272:    root.bindPluginBarApi(api)
275:    for (var id in pluginBarApis) next[id] = pluginBarApis[id]
277:    pluginBarApis = next
281:  function pluginBarApiUsed(pluginId) {
302:  function prunePluginBarApis() {
304:    for (var id in pluginBarApis) {
305:      var api = pluginBarApis[id]
306:      if (root.pluginBarApiUsed(id)) {
313:    pluginBarApis = next
316:  onActivePopoutChanged: syncAllPluginBarApiObjects()
317:  onClickTargetsChanged: syncAllPluginBarApiObjects()
318:  onLayoutConfigChanged: syncAllPluginBarApiObjects()
319:  onModuleSlotsChanged: Qt.callLater(prunePluginBarApis)
322:    for (var id in pluginBarApis) {
324:      if (pluginBarApis[id] && typeof pluginBarApis[id].destroy === "function")
```

**⏺ bash** `cd $OMARCHY_PATH/shell; grep -n "signal\|property" Ui/PanelKeyCatcher.qml Ui/PanelSectionHeader.qml | head -30; grep -rn "preview" ~/.git/info 2>/dev/null | head -2; which preview.py omarchy-plugin-preview 2>&1 | head`

✓ 71 ms

```text
[exit 0, 65 ms]
Ui/PanelKeyCatcher.qml:4:// and emits semantic signals so each panel keeps its own state machine
Ui/PanelKeyCatcher.qml:32:// triggering signals.
Ui/PanelKeyCatcher.qml:36:  property bool blocked: false
Ui/PanelKeyCatcher.qml:38:  signal moveRequested(int dx, int dy)
Ui/PanelKeyCatcher.qml:39:  signal activateRequested()
Ui/PanelKeyCatcher.qml:40:  signal returnRequested()
Ui/PanelKeyCatcher.qml:41:  signal closeRequested()
Ui/PanelKeyCatcher.qml:42:  signal deleteRequested()
Ui/PanelKeyCatcher.qml:43:  signal tabRequested(int direction)
Ui/PanelKeyCatcher.qml:44:  signal textKey(string text)
Ui/PanelSectionHeader.qml:10:  property color foreground: Color.foreground
Ui/PanelSectionHeader.qml:11:  property string fontFamily: Style.font.family
Ui/PanelSectionHeader.qml:12:  property real fontSize: Style.font.caption
which: no preview.py in (/usr/local/bin:/usr/bin:/usr/share/omarchy/bin:~/.local/share/mise/installs/cursor-agent/latest/bin:~/.local/share/mise/shims:~/.local/share/mise/installs/codex/0.162.1/codex-path:~/.local/share/mise/installs/bun/latest/bin:~/.local/share/mise/installs/claude/latest:~/.local/share/mise/installs/codex/latest/bin:~/.local/share/mise/installs/crush/latest/crush_0.98.1_Linux_x86_64:~/.local/share/mise/installs/gemini/latest/node_modules/.bin:~/.local/share/mise/installs/gh/latest/gh_2.102.0_linux_amd64/bin:~/.local/share/mise/installs/node/26.7.0/bin:~/.local/share/mise/installs/npm-playwright/latest/node_modules/.bin:~/.local/share/mise/installs/opencode/latest/node_modules/.bin:~/.local/share/mise/installs/pi/0.85.1/pi:~/.local/share/mise/installs/shellcheck/0.11.0/shellcheck-v0.11.0:~/.local/share/mise/installs/uv/latest/.mise-bins:~/.cargo/bin:~/.local/bin)
which: no omarchy-plugin-preview in (/usr/local/bin:/usr/bin:/usr/share/omarchy/bin:~/.local/share/mise/installs/cursor-agent/latest/bin:~/.local/share/mise/shims:~/.local/share/mise/installs/codex/0.162.1/codex-path:~/.local/share/mise/installs/bun/latest/bin:~/.local/share/mise/installs/claude/latest:~/.local/share/mise/installs/codex/latest/bin:~/.local/share/mise/installs/crush/latest/crush_0.98.1_Linux_x86_64:~/.local/share/mise/installs/gemini/latest/node_modules/.bin:~/.local/share/mise/installs/gh/latest/gh_2.102.0_linux_amd64/bin:~/.local/share/mise/installs/node/26.7.0/bin:~/.local/share/mise/installs/npm-playwright/latest/node_modules/.bin:~/.local/share/mise/installs/opencode/latest/node_modules/.bin:~/.local/share/mise/installs/pi/0.85.1/pi:~/.local/share/mise/installs/shellcheck/0.11.0/shellcheck-v0.11.0:~/.local/share/mise/installs/uv/latest/.mise-bins:~/.cargo/bin:~/.local/bin)
```

Writing the plugin now: a manifest plus a single QML entry point.

**⏺ write** `.config/omarchy/plugins/parker.window-opacity/manifest.json`

```
{
  "schemaVersion": 1,
  "id": "parker.window-opacity",
  "name": "Window Opacity",
  "version": "1.0.0",
  "author": "parker",
  "description": "Live sliders for Hyprland focused/unfocused window opacity",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "Panel.qml"
  },
  "barWidget": {
    "displayName": "Window Opacity",
    "description": "Live sliders for Hyprland focused/unfocused window opacity",
    "category": "System",
    "allowMultiple": false,
    "defaultSection": "right"
  }
}
```

✓ 1 ms

```text
wrote 521 bytes to .config/omarchy/plugins/parker.window-opacity/manifest.json
```

**⏺ write** `.config/omarchy/plugins/parker.window-opacity/Panel.qml`

```
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui
import qs.Commons

// Bar icon + popup with two sliders driving Hyprland's
// decoration:active_opacity / decoration:inactive_opacity live.
//
// Persistence: the chosen values are written inline on this widget's
// shell.json entry ({"id": "parker.window-opacity", "activeOpacity": 0.95,
// "inactiveOpacity": 0.85}) and re-applied whenever the shell starts or
// Hyprland reloads its config (which would otherwise reset them to the
// values from the Lua config).
Panel {
  id: root
  moduleName: "parker.window-opacity"

  readonly property int minPercent: 20
  readonly property int maxPercent: 100

  // Slider state in whole percent.
  property int activePercent: 100
  property int inactivePercent: 100

  // Which row the keyboard cursor is on: 0 = focused, 1 = unfocused.
  property int selectedRow: 0
  property bool cursorActive: false

  // Apply coalescing: while hyprctl is running, remember only the latest values.
  property bool applyQueued: false
  property double lastApplyMs: 0

  function clampPercent(v) {
    var n = Math.round(Number(v))
    if (isNaN(n)) n = root.maxPercent
    return Math.max(root.minPercent, Math.min(root.maxPercent, n))
  }

  function storedPercent(key) {
    var v = root.setting(key, null)
    if (v === null || v === "" || isNaN(Number(v))) return -1
    return root.clampPercent(Number(v) * 100)
  }

  function hasStoredValues() {
    return storedPercent("activeOpacity") >= 0 || storedPercent("inactiveOpacity") >= 0
  }

  function fmt(percent) {
    return (root.clampPercent(percent) / 100).toFixed(2)
  }

  function apply() {
    if (applyProc.running) {
      root.applyQueued = true
      return
    }
    root.applyQueued = false
… (279 more lines in the repository)
```

✓ 1 ms

```text
wrote 10454 bytes to .config/omarchy/plugins/parker.window-opacity/Panel.qml
```

I'll swap the hover overlay for a `HoverHandler`, which doesn't steal hover from the slider, then check that the glyph I used is the right codepoint.

**⏺ edit** `.config/omarchy/plugins/parker.window-opacity/Panel.qml`

```
      HoverHandler {
        onHoveredChanged: if (hovered) {
          root.cursorActive = true
          root.selectedRow = row.rowIndex
        }
      }
```

✓ 1 ms

```text
edited .config/omarchy/plugins/parker.window-opacity/Panel.qml at line 328

[harness note] Read /usr/share/omarchy/default/agents/skills/omarchy/plugins.md first. Bar is omarchy-shell, not Waybar; idle values are seconds. A new plugin goes in .config/omarchy/plugins/<id>/ with a manifest.json; read a built-in plugin's source under /usr/share/omarchy/shell/plugins/ for the patterns, and switch a plugin on by adding its id to shell.json (bar.layout for widgets, plugins for others). Run the validate and preview checks before finishing. Never edit packaged plugins.
```

**⏺ bash** `grep -o 'text: "."' .config/omarchy/plugins/parker.window-opacity/Panel.qml | python3 -c "import sys; [print(hex(ord(l.strip()[7]))) for l in sys.stdin]"`

✓ 89 ms

```text
[exit 0, 85 ms]
0xf05cb
```

The glyph is U+F05CB (`nf-md-opacity`). Next I'll back up `shell.json` and add the widget to the right side of the bar, just before the display widget.

**⏺ bash** `cp .config/omarchy/shell.json .config/omarchy/shell.json.bak.$(date +%s) && python3 - <<'EOF'
import json
p='.config/omarchy/shell.json'
d=json.load(open(p))
r=d['bar']['layout']['right']
i=[e['id'] for e in r].index('omarchy.monitor')
r.insert(i,{"id":"parker.window-opacity"})
open(p,'w').write(jso`

✓ 132 ms

```text
[exit 0, 127 ms]
 .config/omarchy/shell.json | 3 +++
 1 file changed, 3 insertions(+)
diff --git a/.config/omarchy/shell.json b/.config/omarchy/shell.json
index e6202da..5ddb226 100644
--- a/.config/omarchy/shell.json
+++ b/.config/omarchy/shell.json
@@ -53,6 +53,9 @@
         {
           "id": "omarchy.audio"
         },
+        {
+          "id": "parker.window-opacity"
+        },
         {
           "id": "omarchy.monitor"
         },
```

**⏺ check** `build`

✓ 3661 ms

```text
[exit 0, 3655 ms]
plugin parker.window-opacity  (~/.config/omarchy/plugins/parker.window-opacity)
  barWidget: Panel.qml: loaded; drew: 󰗋
    picture: ~/.h0-preview/parker.window-opacity-barWidget.png
PREVIEW: ok
```

I built a window opacity widget for your top bar. It passes the build check and the shell loads it without QML errors, but I couldn't test it on your desktop: the sandbox has no running Hyprland. I also haven't seen the popup itself, because the preview only draws the bar icon.

**How it works**
- The icon sits on the right of the bar, between audio and display. Clicking it opens a small panel with a **Focused** slider, an **Unfocused** slider, and a **Reset** button that sets both back to 100%.
- The sliders run from 20% to 100%, and windows change as you drag.
- You can also use the keyboard: `j`/`k` picks a slider, `h`/`l` moves it 5%, and `Esc` closes the panel. The mouse wheel over a slider works too.

**Keeping your settings after a restart**
- When you let go of a slider, the values are saved on the widget's entry in `shell.json`, e.g. `{"id": "parker.window-opacity", "activeOpacity": 0.9, "inactiveOpacity": 0.75}`.
- They're re-applied whenever the shell starts, so they come back after you log in. Right at login, windows may show your Hyprland config's opacity for a moment until the shell loads.
- Omarchy's toggles and saving a hypr `.lua` file both run `hyprctl reload`, which resets opacity to your config. The widget watches for that and puts your values back.
- Until you move a slider, nothing is saved and the panel just shows Hyprland's current values.

**Things to know**
- Omarchy applies its own default window opacity (98.5% focused / 96% unfocused) to every window. Hyprland multiplies that by these sliders, so 100% here still looks like Omarchy's default, not fully solid.
- The live change uses `hyprctl eval` with a Lua `hl.config(...)` call, falling back to `hyprctl keyword` if that fails. `hyprctl eval` is in your hyprctl's help, but I haven't seen it run.

**Files**
- New: `.config/omarchy/plugins/parker.window-opacity/` (`manifest.json` and `Panel.qml`).
- Changed: `.config/omarchy/shell.json`, which now includes the widget. A backup of the old file is next to it as `shell.json.bak.<timestamp>`.

**To try it:** the shell should pick up the plugin by itself; if it doesn't, run `omarchy-shell shell rescanPlugins`. Drag the sliders and run `hyprctl getoption decoration:active_opacity` to confirm the value changed. If opacity doesn't change, run `hyprctl eval 'hl.config({ decoration = { active_opacity = 0.8 } })'` and send me the output.

*harness: verify check `build` passed*

