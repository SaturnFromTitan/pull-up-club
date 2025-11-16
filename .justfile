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

# watches for code changes and generates code with incremental rebuilds
generate:
  dart run build_runner build

# generate iOS app icons from assets/app_icon.png via flutter_launcher_icons
icons:
  dart run flutter_launcher_icons

# run formatter on all files
format:
  pre-commit run dart-format --all-files

# run pre-commit linters on all files
lint:
  pre-commit run --all-files
