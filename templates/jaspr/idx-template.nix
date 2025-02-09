{ pkgs, mode ? "static", routing ? "none", flutter ? "false", plugins ? "false", ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.11"; # To support latest dart versions.
  packages = [
    pkgs.dart
    pkgs.flutter
  ];
  env = {
    PATH = ["$HOME/.pub-cache/bin"];
  };
  bootstrap = ''    
    dart --version
    dart pub global activate jaspr_cli
    jaspr create --mode=${mode} --routing=${routing} \
      --flutter=${if flutter == "true" then "embedded" else if plugins == "true" then "plugins-only" else "none"} \
      --backend=none "$WS_NAME"
    chmod -R +w "$WS_NAME"
    mv "$WS_NAME" "$out"
    mkdir -p "$out/.idx/"
    cp -rf ${./dev.nix} "$out/.idx/dev.nix"
  '';
}