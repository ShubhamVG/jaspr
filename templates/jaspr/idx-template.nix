{ pkgs, mode ? "static", routing ? "none", flutter ? "false", plugins ? "false", ... }: {
  packages = [
    pkgs.wget
    pkgs.unzip
    pkgs.patchelf
  ];
  bootstrap = ''   
    # Install Dart
    wget https://storage.googleapis.com/dart-archive/channels/stable/release/3.5.4/sdk/dartsdk-linux-x64-release.zip
    unzip dartsdk-linux-x64-release.zip
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" dart-sdk/bin/dart
    chmod +x "dart-sdk/bin/dart"
    # Install Jaspr
    dart-sdk/bin/dart --version
    dart-sdk/bin/dart pub global activate jaspr_cli
    # Create project
    dart-sdk/bin/dart pub global run jaspr_cli:jaspr create --mode=${mode} --routing=${routing} \
      --flutter=${if flutter == "true" then "embedded" else if plugins == "true" then "plugins-only" else "none"} \
      --backend=none "$WS_NAME"
    chmod -R +w "$WS_NAME"
    mv "$WS_NAME" "$out"
    mkdir -p "$out/.idx/"
    cp -rf ${./dev.nix} "$out/.idx/dev.nix"
  '';
}