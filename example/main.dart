// ignore_for_file: unused_local_variable
import 'package:bitwarden_secrets/bitwarden_secrets.dart';

void main() {
  var accessToken = "<your access token>";
  var organizationId = "<your organization id>";

  // Create a bitwarden client
  var bws = BitwardenSecrets(organizationId);

  // Authroize
  bws.accessTokenLogin(accessToken, statePath: "temp.txt");

  // Create a project and secret
  var project = bws.projectCreate("foo-project");
  var secret = bws.secretCreate("foo-api-Key", "xxxx-xxxx-xxxxxxx", project.id);

  // List Secrets
  List<SecretHeader> secrets = bws.secretList();

  // List Projects
  List<Project> projects = bws.projectList();

  // Lookup the value of a secret with a the given key
  var fooApiKey = lookupByName(bws, "foo-api-key").value;
}

Secret lookupByName(BitwardenSecrets bws, String key) {
  var header = bws.secretList().singleWhere((e) => e.key == key);
  return bws.secretGet(header.id);
}
