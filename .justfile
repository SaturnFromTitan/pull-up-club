set shell := ["bash", "-c"]

# default recipe to display help information
@list:
  just --list

# remove files created by tooling and packaging
@clean:
  rm -rf build

# install flutter dependencies
install:
  dart pub get

# run pre-commit linters on all files
lint:
  pre-commit run --all-files

# generate iOS app icons from assets/app_icon.png via flutter_launcher_icons
icons:
  dart run flutter_launcher_icons
