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
  var project = bws.projectCreate("foo-project");
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
