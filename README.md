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

# Example

```dart
  var accessToken = "<your access token>";
  var organizationId = "<your organization id>";

  // Create a bitwarden client
  var bws = BitwardenSecrets(organizationId);

  // Authroize
  bws.accessTokenLogin(accessToken, statePath: "temp.txt");

  // Create a project and secret
  var project = bws.projectCreate("my-project");
  var secret = bws.secretCreate("foo-api-Key", "xxxx-xxxx-xxxxxxx", project.id);

  // List Secrets
  List<SecretHeader> secrets = bws.secretList();

  // List Projects
  List<Project> projects = bws.projectList();

```

## Lookup Secret By Key

To look up a secret by key, you must list all the secrets and search for it.

``` dart
Secret lookupByName(BitwardenSecrets bws, String key) {
  var header = bws.secretList().singleWhere((e) => e.key == key);
  return bws.secretGet(header.id);
}

// Lookup the value of a secret with a the given key
var fooApiKey = lookupByName(bws, "foo-api-key").value;
```

