{ pkgs, mode ? "static", routing ? "none", flutter ? "false", plugins ? "false", ... }: {
  bootstrap = ''   
    # Install Dart
    wget https://storage.googleapis.com/dart-archive/channels/stable/release/3.5.4/sdk/dartsdk-linux-x64-release.zip
    unzip dartsdk-linux-x64-release.zip
    mv dart-sdk ~/.dart-sdk
    echo "export PATH=\"$PATH\":\"$HOME/.dart-sdk/bin\" ">> ~/.bashrc
    source ~/.bashrc
    # Install Jaspr
    dart --version
    dart pub global activate jaspr_cli
    # Create project
    jaspr create --mode=${mode} --routing=${routing} \
      --flutter=${if flutter == "true" then "embedded" else if plugins == "true" then "plugins-only" else "none"} \
      --backend=none "$WS_NAME"
    chmod -R +w "$WS_NAME"
    mv "$WS_NAME" "$out"
    mkdir -p "$out/.idx/"
    cp -rf ${./dev.nix} "$out/.idx/dev.nix"
  '';
}