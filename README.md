# emitron_iOS
iOS version of emitron


## Secrets Management

Secrets should not be checked in to this repo. Instead, update the
__Emitron/Emitron/Configuration/secrets.template.xcconfig__ file, and create
local copies of __secrets.production.xcconfig__ and __secrets.development.xcconfig__.

These two files must be kept up-to-date in the S3 bucket to ensure that both new team
members and CI can build the app.

If you are not creating an official RW build of Emitron, then you are able to place
your own secrets in the secrets file. Contact engineering@razeware.com for details.

### Details

The two `xcconfig` files are used to configure the project. To access the values specified
they must be added to the __Info.plist__ file.

Use the `Configuration` struct to access these values from code.

For more details on this approach, check out https://nshipster.com/xcconfig/
