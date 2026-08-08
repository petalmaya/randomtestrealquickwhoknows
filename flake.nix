{
  description = ''
    Kuru Kuru Bar (personal fork) - standalone flake.

    Packages this repo as a `kurukurubar` binary (a thin wrapper around
    `quickshell -p <this config>`), for running on NixOS without pulling
    in the rest of the Zaphkiel flake this was originally forked out of.

    Deliberately does NOT package a greetd/kurukuruDM greeter target -
    this fork dropped `greeter.qml` entirely (see README.md), so there's
    nothing here to build one from. If you want a greetd-based login
    screen, use upstream (github:Rexcrazy804/Zaphkiel) directly instead
    of this flake.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # quickshell isn't in nixpkgs proper (yet) - pull it from its own
    # flake, same as most niri/quickshell setups do.
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    quickshell,
  }: let
    forEachSystem = fn:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: fn nixpkgs.legacyPackages.${system} system);
  in {
    packages = forEachSystem (pkgs: system: let
      qs = quickshell.packages.${system}.default;

      # only the bits quickshell actually needs at runtime - keeps the
      # store path from dragging in README.md/todo.md/.git/etc, and
      # doubles as a decent "did I forget to add a new top-level dir"
      # checklist whenever the module map in ARCHITECTURE.md changes.
      configSrc = pkgs.lib.fileset.toSource {
        root = ./.;
        fileset = pkgs.lib.fileset.unions [
          ./shell.qml
          ./Data
          ./Layers
          ./Containers
          ./Widgets
          ./Generics
          ./Assets
          ./scripts
        ];
      };

      fontconfig = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.material-symbols
          pkgs.nerd-fonts.noto-sans-mono
          pkgs.librebarcode
        ];
      };

      qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
        pkgs.kdePackages.qtbase
        pkgs.kdePackages.qtdeclarative
        pkgs.kdePackages.qtmultimedia
      ];

      runtimePath = pkgs.lib.makeBinPath [
        pkgs.rembg
        pkgs.brightnessctl
        pkgs.power-profiles-daemon
      ];
    in {
      default = self.packages.${system}.kurukurubar;

      kurukurubar = pkgs.symlinkJoin {
        pname = "kurukurubar";
        version = qs.version or "unstable";
        paths = [qs];
        nativeBuildInputs = [pkgs.makeWrapper];

        postBuild = ''
          makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar \
            --set FONTCONFIG_FILE "${fontconfig}" \
            --set QML2_IMPORT_PATH "${qmlPath}" \
            --prefix PATH : "${runtimePath}" \
            --add-flags '-p ${configSrc}'
        '';

        meta = {
          description = "Kuru Kuru Bar - Quickshell config for niri/mangowc (personal fork, no greeter)";
          mainProgram = "kurukurubar";
          platforms = pkgs.lib.platforms.linux;
        };

        passthru.config = configSrc;
      };
    });

    # NixOS module: installs the package + a `programs.kurukurubar.enable`
    # toggle. Deliberately session/greeter-agnostic - it just puts the
    # binary on PATH and (optionally) autostarts it as a niri/mangowc
    # `spawn-at-startup` style user unit; wire it into your compositor's
    # own startup config or a systemd --user unit as you prefer, same as
    # running `kurukurubar` by hand.
    nixosModules.default = {
      lib,
      pkgs,
      config,
      ...
    }: let
      cfg = config.programs.kurukurubar;
    in {
      options.programs.kurukurubar = {
        enable = lib.mkEnableOption "Kuru Kuru Bar (Quickshell config)";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          self.packages.${pkgs.system}.kurukurubar
        ];
      };
    };

    devShells = forEachSystem (pkgs: system: {
      default = pkgs.mkShell {
        packages = [
          quickshell.packages.${system}.default
          pkgs.qtcreator
        ];
      };
    });
  };
}
