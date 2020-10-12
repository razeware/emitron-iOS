# emitron (iOS)

__emitron__ is the code name for the raywenderlich.com app. This repo contains the code for the iOS version of the app.

## Contributing

To contribute a __feature__ or __idea__ to emitron, create an issue explaining your idea.

If you find a __bug__, please create an issue.

If you find a __security vulnerability__, please contact emitron@razeware.com as soon as possible. See [SECURITY.md](SECURITY.md) for further details.

There is more info about contributing in [CONTRIBUITNG.md](CONTRIBUTING.md).


## Development

__emitron__ runs on iOS 13.3 and greater. It uses SwiftUI and Combine extensively; and since these two technologies were very new at the time of creation, there are plenty of places in the code that could benefit from some refactoring.

Currently, only people that hold an active raywenderlich.com subscription may use emitron. Non-subscribers will be shown a "no access" page on login. Subscribers have access to streaming videos, and a subset of subscribers (ones with a "Professional" subscription) is allowed to download videos for offline playback.

### Secrets Management

__emitron__ requires 2 secrets:

- `SSO_SECRET`. This is used to ensure secure communication with `guardpost`, the raywenderlich.com authentication service. Although this is secret, a sample secret is provided inside this repo. This shouldn't be used to create a beta or production build.
- `APP_TOKEN`. Required in order to enable downloads. This is not provided in the repo, and is not generally available.

The secrets are stored in __Emitron/Emitron/Configuration/secrets.*.xcconfig__ files, with one file for each deployment stage. These files have entries in the .gitignore, so they won't appear when you first download the repo.

To generate these files after you've first cloned the repository, execute the following command:

```bash
$ scripts/generate_secrets.sh
```

This will make the required copies of the template file, which includes an SSO secret appropriate for open-source development.

> __NOTE:__ To get the release build secrets, check the emitron S3 bucket, or contact emitron@razeware.com. Developers should never need these, as CI will handle it.

If you are working on the download functionality and are having problems without an `APP_TOKEN`, contact emitron@razeware.com and somebody will assist you with your specific needs.

#### Details

The two `xcconfig` files are used to configure the project. To access the values specified, these files must be added to the __Info.plist__ file.

Use the `Configuration` struct to access these values from code.

For more details on this approach, check out https://nshipster.com/xcconfig/


### SwiftLint

SwiftLint runs as part of the build process in Xcode, and errors/warnings are surfaced in Xcode as well. Please ensure that you run SwiftLint before submitting a pull request.

To install SwiftLint using homebrew:

```bash
$ brew install swiftlint
```

Xcode will automatically run SwiftLint if it is installed.

### Continuous Integration & Deployment

__emitron__ uses GitHub Actions to perform continuous integration and deployment. Every PR is built and tested before it can be merged.

- Merges to `development` will create a new build of the emitron β app on TestFlight.
- Merges to `production` will create a new build of the emitron production app on TestFlight.




