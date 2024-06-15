import 'package:bitwarden_secrets/bitwarden_secrets.dart';
import 'package:test/test.dart';

void main() {
  test('Test All', () {
    // Just a single test because testing with a free account where
    // we can only create 2 projects

    var accessToken = "<your access token>";
    var organizationId = "<your org id>";
    final bws = BitwardenSecrets(organizationId);

    // Authenticate
    bws.accessTokenLogin(accessToken);

    // Delete all 'Temp' projects
    for (var p in bws.projectList().where((e) => e.name.startsWith("Temp"))) {
      bws.projectDelete(p.id);
    }
    var n = bws.projectList().length;

    // Create
    var p = bws.projectCreate("Temp");

    // List
    var list = bws.projectList();
    expect(list.length, 1 + n);
    _expecteProject(list.firstWhere((e) => e.id == p.id), p);

    // Update
    var p2 = bws.projectUpdate(p.id, "Temp2");
    expect(p2.name, "Temp2");

    // Get
    var p3 = bws.projectGet(p.id);
    _expecteProject(p3, p2);

    // Delete
    bws.projectDelete(p.id);
    expect(bws.projectList().length, 0 + n);

    // DeleteList
    var p4 = bws.projectCreate("Temp 1");
    var p5 = bws.projectCreate("Temp 2");
    expect(bws.projectList().length, 2 + n);
    bws.projectDeleteList([p4.id, p5.id]);
    expect(bws.projectList().length, 0 + n);

    // Secret Create
    var p6 = bws.projectCreate("Temp");
    var p7 = bws.projectCreate("Temp2");
    var s1 = bws.secretCreate("Key1", "Value", p6.id);
    var s2 = bws.secretCreate("Key2", "Value", p6.id, note: "Note");
    var s3 = bws.secretCreate("Key3", "Value", p6.id);

    // Secret Get
    bws.secretGet(s3.id);

    // Secret Update
    var s4 = bws.secretUpdate(s2, key: "x");
    expect(s4.key, "x");

    var s5 = bws.secretUpdate(s2, value: "x");
    expect(s5.value, "x");

    var s6 = bws.secretUpdate(s2, note: "x");
    expect(s6.note, "x");

    var s7 = bws.secretUpdate(s2, projectId: p7.id);
    expect(s7.projectId, p7.id);

    bws.projectDeleteList([p6.id, p7.id]);
  });
}

void _expecteProject(Project a, Project m) {
  expect(a.id, m.id);
  expect(a.name, m.name);
  expect(a.organizationId, m.organizationId);
  expect(a.creationDate, m.creationDate);
  expect(a.revisionDate, m.revisionDate);
}
