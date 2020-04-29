# emitron (iOS)

__emitron__ is the code name for the raywenderlich.com app. This repo contains the code
for the iOS version of the app.


## Development

### Secrets Management

__emitron__ requires 2 secrets:

- `SSO_SECRET`. This is used to ensure secure communication with `gaurdpost`, the raywenderlich.com authentication service. Although this is secret, a sample secret is provided inside this repo. This shouldn't be used to create a beta or production build.
- `APP_TOKEN`. Required in order to enable downloads. This is not provided in the repo, and is not generally available.

The secrets are stored in __Emitron/Emitron/Configuration/secrets.*.xcconfig__ files, with one file for each deployment stage. These file are gitignored, so won't appear when you first download the repo.

To generate these files when you first clone:

```bash
$ scripts/generate_secrets.sh
```

This will make the required copies of the template file, which includes an SSO secret appropriate for open-source development.

> __NOTE:__ To get the release build secrets, check the emitron S3 bucket, or contact engineering@razeware.com. Developers should never need these, as CI will handle it.

If you are working on the download functionality and are having problems without an `APP_TOKEN` contact engineering@razeware.com and somebody will assist.

#### Details

The two `xcconfig` files are used to configure the project. To access the values specified
they must be added to the __Info.plist__ file.

Use the `Configuration` struct to access these values from code.

For more details on this approach, check out https://nshipster.com/xcconfig/


### SwiftLint

As part of the build process in Xcode, SwiftLint is run, and errors/warnings are surfaced in Xcode. Please ensure that you run SwiftLint before submitting a pull request.

To install SwiftLint using homebrew:

```bash
$ brew install swiftlint
```

Xcode will automatically run SwiftLint if it is installed.


### Continuous Integration & Deployment

__emitron__ uses GitHub Actions to perform continuous integration and deployment. Every PR is built and tested before it can be merged.

- Merges to `development` will create a new build of the emitron β app on TestFlight.
- Merges to `master` will create a new build of of the emitron production app on TestFlight.




