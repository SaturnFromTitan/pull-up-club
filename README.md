# 💪 Pull-Up Club

The app to the great and simple instructions by kboges:

[The plan for doubling your max pull-ups!](https://www.youtube.com/watch?v=w9Mu-azxol8)

## Design

- [Figma Make project](https://www.figma.com/make/FPf0WLYOC5cKtXhh9Yhdgh/Pull-Up-Doubler?node-id=0-1&p=f&t=8SOteVgZCKzLM9C0-0)
- [Published prototype](https://dot-gothic-32505069.figma.site)

## Release

This project uploads a signed build to TestFlight on every push to `main` using Fastlane and GitHub Actions.
Later on there will be a manual workflow to create an app store & GitHub release.
The idea is that the latest version is always available on TestFlight and once we're happy with it, it can
be published to the App Store.

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
