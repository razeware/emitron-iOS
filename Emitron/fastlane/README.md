fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios ci_upload_beta_testflight

```sh
[bundle exec] fastlane ios ci_upload_beta_testflight
```

Push a new beta build to TestFlight

### ios ci_upload_release_testflight

```sh
[bundle exec] fastlane ios ci_upload_release_testflight
```

Push a new production build to TestFlight

### ios ci_upload_release_appstore

```sh
[bundle exec] fastlane ios ci_upload_release_appstore
```

Push a new release version to App Store Connect ready for release

### ios tests

```sh
[bundle exec] fastlane ios tests
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
