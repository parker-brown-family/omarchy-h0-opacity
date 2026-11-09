# How h0 built Window Opacity

h0 (a coding-agent harness) running Claude Opus 5.5 (claude-opus-5-5), fitting `omarchy-v4`, in a sandbox holding a copy of an Omarchy 4 home directory. It was sent the idea below, then, after each reply, the same automatic checks ran; when one failed, the next prompt was written from a fixed template from what the check printed, the way a person pastes back an error. Nobody edited its files. The protocol is in the omarchy-h0-builds repository.

| prompt | what was sent | turns | prompt tokens | output tokens | cost | minutes | checks after it |
|---|---|---|---|---|---|---|---|
| 1 | the idea | 25 | 1,046,251 | 14,790 | $0.83 | 2.9 | all pass |
| **all** | | **25** | | | **$0.83** | **2.9** | |

## Prompt 1

```text
Build me an Omarchy shell plugin that puts a window opacity control in my top bar. Clicking it should open a small panel with two sliders, one for the focused window and one for unfocused windows, that change Hyprland's opacity live. Keep my settings after a restart.
```

25 turns, $0.83, 173 s. Stop: `end_turn`.

Checks after it:

- ✓ `found`: .config/omarchy/plugins/parker.window-opacity
- ✓ `validate`
- ✓ `loads`: plugin parker.window-opacity  (~/.config/omarchy/plugins/parker.window-opacity)
- ✓ `switched-on`: id parker.window-opacity
- ✓ `sets-opacity`: read from the code

<details><summary>h0's reply</summary>

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

</details>

Every tool call and its result: [SESSION.md](SESSION.md). The hash-chained trace: [session/trace.jsonl](session/trace.jsonl).
