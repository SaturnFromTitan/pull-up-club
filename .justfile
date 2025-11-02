set shell := ["bash", "-c"]

# default recipe to display help information
@list:
  just --list

# remove files created by tooling and packaging
@clean:
  rm -rf build

# install flutter dependencies
install:
    flutter pub get

# run linter and formatter
lint: install
    flutter analyze
    dart format --set-exit-if-changed .

# generate iOS app icons from assets/app_icon.png via flutter_launcher_icons
icons: install
    dart run flutter_launcher_icons
