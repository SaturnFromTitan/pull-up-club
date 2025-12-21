# 💪 Pull-Up Club

The app to the great and simple instructions by kboges:

[The plan for doubling your max pull-ups!](https://www.youtube.com/watch?v=w9Mu-azxol8)

## Design

- [Figma Make project](https://www.figma.com/make/FPf0WLYOC5cKtXhh9Yhdgh/Pull-Up-Doubler?node-id=0-1&p=f&t=8SOteVgZCKzLM9C0-0)
- [Published prototype](https://dot-gothic-32505069.figma.site)

## Release

This project uploads a signed build to TestFlight on every push to `main` using Fastlane and GitHub Actions.
Releasing to the App Store is done manually via App Store Connect.

### App Store

You can download it in the [Apple App Store](https://apps.apple.com/app/pull-up-club/id6754757771)!

### Certificates for Fastlane

The certificates that fastlane uses to sign the app for releasing it are stored in a separate, [private github repo](https://github.com/SaturnFromTitan/pull-up-club-certificates).

#### Initial Certificate setup

Please run the following locally: Firstly, install the Ruby dependencies:

```sh
cd ios
rbenv local 3.3.9 # or whatever version you want to run
# ensure your PATH is updated so the new version is picked up
rbenv exec gem install bundler
bundle config set --local path 'vendor/bundle'
bundle install
```

Then publish the certificates to the repository via

```sh
bundle exec fastlane match appstore \
      --git_url "${MATCH_GIT_URL:-git@github.com:SaturnFromTitan/pull-up-club-certificates.git}" \
      --app_identifier "${APP_BUNDLE_ID:-com.saturnfromtitan.pullupclub}"
```

## Local Setup

### Prerequisites

The following prerequisites have to be installed:

- [just](https://github.com/casey/just#installation) (Command Runner)
- [pre-commit](https://pre-commit.com/#installation) (git hooks for linters)
- [Flutter SDK including Dart](https://docs.flutter.dev/get-started/quick)

With that, you cna now install the dependencies using

```sh
just install
```

and **optionally** you can also install the pre-commit hooks via

```sh
pre-commit install
```

### Privacy Policy

The privacy policy is located in `docs/privacy-policy.html` and is hosted on GitHub Pages. To update the "Last updated" date from git commit history, run:

```sh
just update-privacy-date
```

This will automatically extract the last commit date for the privacy policy file and update it in the HTML.

## Logging and Crash Reporting Guide

The app uses a multi-layered logging and error reporting system:

1. **File-based logging**: All logs are written to a file on the device
2. **Sentry integration**: Errors and warnings are automatically sent to Sentry (if configured)
3. **Console logging**: Development logs are printed to console (debug mode only)

## Cloud Sync

When signing in with an Apple ID, the workout data can be synced to a remote backend (Supabase).
The sync assumes that workouts are immutable, i.e. updating workouts or workout sets is not allowed locally OR on the server
(setting `deleted_at` is the single exception to this rule).
In the app itself, this won't be possible in the forseeable future anyway.
On the server, it is in principle possible via the admin interface.
But instead of altering an existing resource, a new resource with the same attributes should be added and the old one soft-deleted.

Syncs are performed:

| When                                       | scope |
|--------------------------------------------|-------|
| After signing in (e.g. with Apple)         | full  |
| On app start                               | full  |
| After completing a workout locally         | push  |
| After deleting a workout locally           | push  |

If the sync in its current form proves to be too inefficient, we should introduce

- a queue for workout completion / deletion that can be processed asyncroniously
  -> local changes are pushed to the server reliably and targeted
- delta sync (required modifiedAt field on the server and locally)
  -> latest server changes are pulled efficiently
- a full sync would then only be required upon sign-in
