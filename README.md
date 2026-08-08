# Kuru Kuru Bar (personal fork)

https://github.com/user-attachments/assets/26b32435-a932-4a63-8545-24e5039714b6

- Wallpaper source: [The Herta by meirong](https://www.pixiv.net/artworks/126270092)

> **This is a personal fork**, not the upstream project. It's forked from
> [Rexcrazy804](https://github.com/Rexcrazy804)'s original Kuru Kuru Bar
> (part of their [Zaphkiel](https://github.com/Rexcrazy804/Zaphkiel) NixOS
> flake) and adapted to run standalone on a Debian machine outside of
> that NixOS setup. On top of the port, this fork adds its own stuff not
> in upstream (app launcher w/ wallpaper picker mode, extra IPC targets,
> assorted fixes) and drops pieces that only made sense in the original
> NixOS/greetd context (see below).
>
> **Experimental.** This is tracked and iterated on for one specific
> machine/config, not tested across distros or hardware. Expect rough
> edges, and check before assuming something works as
> documented.

A compat and adorable bar designed with the goal of speeening the kuru kuru.
Designed in acordance to google's material 3 guidelines.
You may generate colors from your wallpaper using [matugen](https://github.com/InioX/matugen).
(Upstream ships a matugen template via their NixOS module; on this fork
you'll need to supply your own template or point matugen's config at one -
see `scripts/applyMatugen.sh`.)

| [Kokomi by omochichi96](https://twitter.com/omochichi96/status/1758113643521245240) | [Shinobu by solipsist](https://www.pixiv.net/en/artworks/119108248) |
|----------|----------|
|![image](https://github.com/user-attachments/assets/7ed235f1-0a49-4546-be01-16197dc7940f) | ![image](https://github.com/user-attachments/assets/16cb7c57-92b2-4178-a5e6-d9023012f473) |

### Dependencies

General list (package manager agnostic):

- quickshell
- niri (or mangowc — both are auto-detected at runtime)
- material-symbols
- nerdfonts (the wallpaper picker and glyph icons expect the patched Noto Sans Mono, "NotoSansM Nerd Font Propo")
- [librebarcode](https://graphicore.github.io/librebarcode/) (should be available in the google-fonts package)
- qt6declarative-labs (Qt.labs.folderlistmodel, Qt.labs.platform — used by the wallpaper picker)
- qtmultimedia
- powerprofilesdaemon (optional)
- brightnessctl (optional)
- rembg (required for foreground layer effect)

> #### Installing on Debian
>
> quickshell itself isn't in Debian's repos — build/install it per the
> [quickshell docs](https://quickshell.org) first (or grab a prebuilt if
> one's available for your Debian version), then the rest of this maps to:
>
> ```sh
> sudo apt install \
>   fonts-noto-color-emoji \
>   qml6-module-qt-labs-folderlistmodel \
>   qml6-module-qt-labs-platform \
>   qml6-module-qtmultimedia \
>   qml6-module-qtquick-effects \
>   qt6-multimedia-plugins \
>   power-profiles-daemon \
>   brightnessctl \
>   fonts-noto \
>   pipx
> ```
>
> A few notes:
> - **material-symbols** and the **nerd-fonted Noto Sans Mono** aren't
>   packaged on Debian — grab them manually: [Material Symbols](https://fonts.google.com/icons)
>   and the "NotoSansM Nerd Font Propo" variant from
>   [nerdfonts releases](https://github.com/ryanoasis/nerd-fonts/releases),
>   then drop them in `~/.local/share/fonts` and run `fc-cache -f`.
> - **librebarcode** isn't in Debian's `fonts-google-*` packages either —
>   download it from the [librebarcode site](https://graphicore.github.io/librebarcode/)
>   and install it the same way as above.
> - **rembg** is a Python package, not a system one — `pipx install rembg`
>   (or a venv) is more reliable on Debian than hunting for a system
>   package.
> - You still need a compositor: niri or mangowc, neither of which is in
>   Debian's default repos — follow their own install instructions.

### Installation

1. Install the above dependencies using your favourite package manager
1. git clone this repo
1. copy `kurukurubar` folder into `~/.config/quickshell`
1. spawn the bar by running `quickshell`
1. VERY IMPORTANT, press hold the spinning herta to spin her faster - the council of kurukuru

> make sure you are not creating `.config/quickshell/kurukurubar`,
> in which case you will need to pass the arg `-c kurukurubar` in step 4.

#### NixOS / flake

This repo also ships its own standalone `flake.nix` (separate from, and
much smaller than, the upstream Zaphkiel flake this fork originally came
out of - no greeter, no home-manager, no rest-of-the-system opinions,
just this bar):

```sh
nix run github:<you>/<this-repo>            # try it without installing
nix profile install github:<you>/<this-repo> # install the `kurukurubar` binary
```

Or add it as a flake input and enable `programs.kurukurubar.enable = true;`
via the exported `nixosModules.default` for a system-wide install. The
module only puts the binary on `$PATH` - autostarting it is left to your
compositor's own startup config (niri's `spawn-at-startup`, mangowc's
autostart, a systemd `--user` unit, etc.), same as running `kurukurubar`
by hand.

**No greeter target.** Unlike upstream's Zaphkiel flake (which can build
a greetd-based `kurukuruDM` greeter from `greeter.qml`), this flake only
packages the logged-in-session bar - matches this fork not shipping
`greeter.qml` at all (see below).

### Lock Screen and Foreground Isolation

The lock screen requires a wallpaper to be set
either at the default location `~/.config/background`
or by manually specifying the path with:
(prefer absolute paths '/' or paths starting from your home directory '~/')

```sh
quickshell ipc call config setWallpaper ~/Path/to/your/wallpaper
```

Once the wallpaper is set correctly you may launch the lock screen like so

```sh
quickshell ipc call lockscreen lock
```

The `Fg Layer Extraction` option must be turned on in the Kuru Settings tab
to enable the Foreground isolation effect.
**First run will take time** as rembg downloads the required birefnet model
and processes your wallpaper.
Subsequent runs will depend on your hardware
but the results are cached
so switching to already processed images are instant.

> **Not present in this fork**: upstream also ships `greeter.qml`, a
> `greetd`-based pre-login greeter (plus a `kurukuruDM` NixOS module and a
> QEMU VM test rig for it). This fork removes all of that — it's built to
> run under an already-installed display manager (SDDM here), not to
> replace one. If you want a greetd-based login screen, use upstream
> directly instead of this fork.

### Known Issues

- Herta faceIcon: symlink an image (of any image type) to ~/.face.icon

## Acknowledgement

- AlbumCover svg by [Squirrel Modeller](https://github.com/SquirrelModeller)
- Particle System ~~stolen from~~ inspired by [soramanew/rainingkuru](https://github.com/soramanew/rainingkuru)

## Many thanks to these homies :>

end_4, sora, a certain individual that has not yet returned, foxxed, starch,
aureus, caesus, oyudays, lysec, friday and squirrel modeller

## Components outline

> WARNING <br>
> outdated, will need to redo this later

```
| Notch
- | TopBar
- - | WorkspacePill
- - | MprisDot
- - | TimePill
- - | BrightnessDot
- - | AudioSwiper
- - | BatteryPill
- | ExpanededPane
- - | CentralPane
- - - | HomeView
- - - - | GreeterWidget
- - - - | TrayItemMenu (exported from TrayItem)
- - - - | TrayItem
- - - | CalenderView
- - - | SystemView
- - - - | SessionDots
- - - | MusicView
- - - - | MprisItem
- - - | SettingsView
- - - - | PowerTab
- - - - - | PowerInfo
- - - - | AudioTab
- - - - - | AudioSlider
- - | KuruKuru
- - - | KuruParticleSystem
- - - | NotifDots
- | PopupPane
- - | PopupNotification
- | InboxPane
- - | Notification
```

> with \<3 by Rexiel Scarlet
