# Dotfiles

macOS desktop setup: Ghostty + Starship terminal, Yabai + skhd tiling window
management, and a two-bar SketchyBar menu bar replacement. Managed with GNU
Stow, one package per tool.

## Install order (fresh machine)

1. Install Homebrew if not already present
2. `brew bundle --file=Brewfile` — installs everything below in one shot
  1.    (Homebrew will prompt to `brew trust` third-party taps like
   FelixKratz/formulae the first time you install from them — this is
   expected, not an error.)
3. `cd ~/.dotfiles && stow ghostty starship yabai skhd sketchybar bottom_bar zsh wallpaper-clock`
4. Grant macOS permissions (see below) — most of this build silently fails
   without them, and the failure mode is rarely an obvious error
5. `brew services start sketchybar` (this also spawns `bottom_bar`, see below)
6. `yabai --start-service && skhd --start-service`
7. `launchctl load ~/Library/LaunchAgents/com.raborn.wallpaper-clock.plist`
   (only needed once — see Wallpaper section below)

## Required macOS permissions

Grant these under System Settings > Privacy & Security before expecting
things to work. Nothing here throws an obvious error when missing; it just
silently doesn't do anything.

| App | Permission | Why |
|---|---|---|
| yabai | Accessibility | window management |
| skhd | Accessibility + Input Monitoring | hotkeys |
| sketchybar | Screen Recording | front_app widget |
| Ghostty | Full Disk Access | needed for `shortcuts run` (weather) to work at all |

## Architecture notes / things that will bite you

- **macOS's system `/bin/bash` is version 3.2** (pre-GPLv3, frozen since 2007).
  `$'\uXXXX'` Unicode escapes silently fail on it, no error, just literal
  text. Every icon in this config uses `$(printf '\xEF\x80\x97')`-style raw
  UTF-8 byte escapes instead, which work on any bash version. If you add a
  new icon, compute the byte sequence, don't use `\u`.

- **SketchyBar has no concept of "rows."** `left`/`center`/`right` are each
  one continuous horizontal line; `y_offset` only shifts pixels visually,
  it does not reserve separate layout space. The two-band trick (one bar,
  offsetting content up/down) will visually collide if you put items in the
  same position group across both "bands." This repo instead runs **two
  fully independent SketchyBar daemons**: `sketchybar` (top) and `bottom_bar`
  (bottom), the latter a symlink of the same binary under a different name,
  which macOS treats as a separate service with its own config at
  `~/.config/bottom_bar/sketchybarrc`.

- **Scripts shared across the two bars must use `$BAR_NAME`, not
  `sketchybar` hardcoded.** SketchyBar sets this env var automatically to
  whichever bar invoked the script. Hardcoding `sketchybar --set ...` in a
  script that only exists in `bottom_bar`'s item list fails silently.

- **`bottom_bar` is spawned by the top bar's own `sketchybarrc`**, not by
  `brew services` directly (Homebrew's service definition only knows about
  the literally-named `sketchybar` binary). The spawn is guarded with
  `pgrep -q bottom_bar` so reloading the top config doesn't launch
  duplicates. If the bottom bar seems stuck or duplicated, `pkill bottom_bar`
  before restarting `sketchybar`.

- **`networksetup -getairportnetwork` is dead** as of macOS 15 (Sequoia) —
  Apple gated SSID lookup as a privacy measure. The network widget checks
  `ipconfig getifaddr en0` for connectivity instead of showing the actual
  network name.

- **Direct MediaRemote framework access is entitlement-gated since macOS
  15.4.** Now Playing info comes from the `media-control` CLI
  (`ungive/mediaremote-adapter`), a properly signed helper, not a raw API
  call. Control commands: `play`, `pause`, `toggle-play-pause`, `next-track`,
  `previous-track` — run `media-control --help` for the full list before
  wiring up anything new.

- **Weather uses macOS's own Shortcuts app + WeatherKit**, not a public API.
  There's a Shortcut named `GetWeatherText` (Get Current Weather → Text →
  Stop and Output) invoked via `shortcuts run --output-path`. This isn't
  version-controlled since Shortcuts live outside the filesystem; if you're
  setting this up fresh, recreate it in the Shortcuts app (see
  `bottom_bar/.config/bottom_bar/plugins/weather.sh` for exact invocation).

- **Nerd Font icon codepoints are easy to get wrong from memory or docs.**
  When adding a new icon, verify it renders on `nerdfonts.com/cheat-sheet`
  in your actual installed font before committing to a codepoint — several
  guessed codepoints in this build's history turned out to be deprecated or
  wrong. App logos (Firefox, Steam, Finder, etc.) use `sketchybar-app-font`'s
  ligature syntax instead (`icon=":firefox:"` with
  `icon.font="sketchybar-app-font:Regular:16.0"`), which sidesteps codepoint
  guessing entirely for anything already in that font's icon set.

- **SketchyBar's `background.padding_left/right` does not expand a pill's
  width** the way it sounds like it should (there's an open upstream bug
  where it can overwrite the item's own padding instead of adding to it).
  For an icon-only item (label off), the pill's width is controlled by
  `icon.padding_left`/`icon.padding_right`; the outer `padding_left/right`
  only controls spacing *between* items, not the pill itself.

## Wallpaper: hourly pixel-art cycle

The desktop picture changes on the hour, cycling through 24 pixel-art city
scenes (`~/.dotfiles/wallpapers/pixel-city/0000_night.png` through
`2300_evening.png`, one file per hour, image files themselves are **not**
part of the `wallpaper-clock` Stow package — they're plain files sitting
directly in the repo, not symlinked anywhere).

**How it works:** `wallpaper-clock/bin/wallpaper-clock.sh` reads the
current hour, finds the matching `HH00_*.png` file, and points every
entry in macOS's wallpaper store
(`~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`)
at it, then `killall WallpaperAgent` so the agent relaunches and reloads
the file. That store is what covers *all* spaces and displays at once.
A launchd agent
(`wallpaper-clock/Library/LaunchAgents/com.raborn.wallpaper-clock.plist`)
runs that script at the top of every hour via 24 `StartCalendarInterval`
entries, plus once immediately on load. `StartCalendarInterval` (not a
plain interval timer) matters here specifically because it's a laptop —
launchd re-runs a missed hourly firing shortly after wake if the Mac was
asleep when it was due.

**Why not `desktoppr`:** it only sets the space currently on screen, and
because WallpaperAgent holds the whole store in memory and writes it back
on any wallpaper change, calling desktoppr *after* editing the store makes
the agent clobber the edit with its stale copy — which looked like the
wallpaper not updating at all. It's kept only as a fallback for macOS
versions predating the store.

**To change which image plays at a given hour:** replace or repaint the
corresponding `HH00_*.png` file in `~/.dotfiles/wallpapers/pixel-city/`
— same filename, same 3024x1964 resolution, no script or plist changes
needed. The label after the hour prefix (`_night`, `_dawn`, etc.) is
cosmetic; only the `HH00_` prefix is matched.

**To change the schedule, script logic, or add a second display later:**
edit `wallpaper-clock/bin/wallpaper-clock.sh` or the `.plist` directly in
the repo (both are Stow symlinks back to it, so no copying), then reload:
```
launchctl unload ~/Library/LaunchAgents/com.raborn.wallpaper-clock.plist
launchctl load ~/Library/LaunchAgents/com.raborn.wallpaper-clock.plist
```

**To test a change without waiting for the next hour:**
```
launchctl kickstart -k gui/$(id -u)/com.raborn.wallpaper-clock
cat /tmp/wallpaper-clock.log   # confirms which file it picked and why
```

## Structure

Each top-level directory is a Stow package: `ghostty/`, `starship/`,
`yabai/`, `skhd/`, `sketchybar/`, `bottom_bar/`, `zsh/`,
`wallpaper-clock/`. Run `stow <package>` from the repo root to symlink it
into `$HOME`.
