<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# Bitwarden Secrets

Unoficial driver of the [Bitwarden secrets Manager SDK](https://bitwarden.com/help/secrets-manager-sdk/)

## Example

```dart
// ignore_for_file: unused_local_variable
import 'dart:ffi';
import 'dart:io';
import 'package:bitwarden_secrets/bitwarden_secrets.dart';


void main() {
  var accessToken = "<your access token>";
  var organizationId = "<your organization id>";

  // Create a bitwarden client
  var bws = BitwardenSecrets(organizationId, loadBitwardenLib());

  // Authroize
  bws.accessTokenLogin(accessToken);

  // Create a project and secret
  var project = bws.projectCreate( "foo-project");
  var secret = bws.secretCreate("foo-api-Key", "xxxx-xxxx-xxxxxxx", project.id);

  // List Secrets
  List<SecretIdentifier> secrets = bws.secretList();

  // List Projects
  List<Project> projects = bws.projectList();

  // Lookup the value of a secret with a the given key
  var fooApiKey = lookupByName(bws, "foo-api-key").value;
}

Secret lookupByName(BitwardenSecrets bws, String key) {
  var header = bws.secretList().singleWhere((e) => e.key == key);
  return bws.secretGet(header.id);
}

DynamicLibrary loadBitwardenLib() {
  if (Platform.isWindows) {
    return DynamicLibrary.open("native/bitwarden_c.dll");
  } else if (Platform.isAndroid || Platform.isLinux || Platform.isFuchsia) {
    return DynamicLibrary.open("native/bitwarden_c.so");
  } else if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open("native/bitwarden_c.dynlib");
  } else {
    throw Exception("Unsupported platform: ${Platform.operatingSystem}");
  }
}
```

## Dependancies

This package relies on the shared library `bitwarden_c` which should be realeased next to your application.  `bitwarden_c` can be built from rust source for your platform using:

```bash
# Install rust if needed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build 
git clone https://github.com/bitwarden/sdk.git
cd sdk
cargo build --release -p bitwarden-c

# Copy library to project directory
# edit extension (dll for windows, dylib for mac, etc) and <my_project_path> as needed
cp  target/release/bitwarden_c.so  <my_project_path>/native/
```