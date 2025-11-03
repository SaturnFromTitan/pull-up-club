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

# update dependencies
upgrade:
  flutter pub upgrade

# run linter and formatter
lint: install
  dart fix --apply
  dart format --set-exit-if-changed .
  flutter analyze

# generate iOS app icons from assets/app_icon.png via flutter_launcher_icons
icons: install
  dart run flutter_launcher_icons
