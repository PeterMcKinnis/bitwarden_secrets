/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'dart:convert';
import 'package:bitwarden_secrets/src/client.dart';

class BitwardenSecrets {
  BitwardenSecrets(String organizationId, {String? identityUrl, String? apiUrl})
      : _organizationId = organizationId,
        _client = BitwardenClient(BitwardenClientSettings(
            apiUrl: apiUrl,
            identityUrl: identityUrl,
            userAgent: "Bitwarden DART-SDK",
            deviceType: windows_desktop_device_type));

  final BitwardenClient _client;
  final String _organizationId;

  void accessTokenLogin(String accessToken, {String? statePath}) {
    var command = {
      "accessTokenLogin": {
        "accessToken": accessToken,
        "stateFile": statePath,
      }
    };

    var raw = _checkResponse(_client.runCommand(jsonEncode(command)));
    print(raw);
  }

  Map<String, dynamic> _checkResponse(String raw) {
    var response = _Response.fromJson(jsonDecode(raw));
    if (response.success) {
      return response.data!;
    } else {
      throw Exception("bitwarden client error: ${response.errorMessage}");
    }
  }

  Secret secretCreate(String key, String value, String projectId,
      {String note = ""}) {
    var command = {
      "secrets": {
        "create": {
          "_organizationId": _organizationId,
          "key": key,
          "value": value,
          "projectIds": [projectId],
          "note": note
        }
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Secret.fromJson(json);
  }

  void secretDelete(String secretId) {
    var command = {
      "secrets": {
        "delete": {
          "ids": [secretId]
        }
      }
    };
    _checkResponse(_client.runCommand(jsonEncode(command)));
  }

  void secretDeleteList(List<String> secretIds) {
    var command = {
      "secrets": {
        "delete": {"ids": secretIds}
      }
    };
    _checkResponse(_client.runCommand(jsonEncode(command)));
  }

  Secret secretUpdate(Secret secret,
      {String? key, String? value, String? note, String? projectId}) {
    var command = {
      "secrets": {
        "update": {
          "id": secret.id,
          "_organizationId": _organizationId,
          "key": key ?? secret.key,
          "value": value ?? secret.value,
          "note": note ?? secret.note,
          "projectIds": [projectId ?? secret.projectId]
        }
      }
    };

    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Secret.fromJson(json);
  }

  Secret secretGet(String secretId) {
    var command = {
      "secrets": {
        "get": {"id": secretId}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Secret.fromJson(json);
  }

  List<SecretHeader> secretList() {
    var command = {
      "secrets": {
        "list": {"_organizationId": _organizationId}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return (json["data"])
        .map<SecretHeader>((e) => SecretHeader.fromJson(e))
        .toList();
  }

  Project projectCreate(String name) {
    var command = {
      "projects": {
        "create": {"name": name, "_organizationId": _organizationId}
      }
    };

    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Project.fromJson(json);
  }

  void projectDeleteList(List<String> projectIds) {
    var command = {
      "projects": {
        "delete": {
          "ids": projectIds,
        }
      }
    };
    _checkResponse(_client.runCommand(jsonEncode(command)));
  }

  void projectDelete(String projectId) {
    projectDeleteList([projectId]);
  }

  Project projectUpdate(String projectId, String name) {
    var command = {
      "projects": {
        "update": {
          "_organizationId": _organizationId,
          "id": projectId,
          "name": name,
        }
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Project.fromJson(json);
  }

  Project projectGet(String projectId) {
    var command = {
      "projects": {
        "get": {
          "id": projectId,
        }
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Project.fromJson(json);
  }

  List<Project> projectList() {
    var command = {
      "projects": {
        "list": {"_organizationId": _organizationId}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return (json["data"] as List<Object?>)
        .map((e) => Project.fromJson(e as Map<String, Object?>))
        .toList();
  }
}

class _Response {
  bool success;
  String? errorMessage;
  Map<String, Object?>? data;

  // Constructor
  _Response({
    required this.success,
    required this.errorMessage,
    required this.data,
  });

  // fromJson function
  factory _Response.fromJson(Map<String, dynamic> json) {
    return _Response(
      success: json['success'] as bool,
      errorMessage: json['errorMessage'],
      data: json['data'],
    );
  }
}

class Secret {
  final String id;
  final String organizationId;
  final String projectId;
  final String key;
  final String value;
  final String note;
  final DateTime creationDate;
  final DateTime revisionDate;

  Secret({
    required this.id,
    required this.organizationId,
    required this.projectId,
    required this.key,
    required this.value,
    required this.note,
    required this.creationDate,
    required this.revisionDate,
  });

  factory Secret.fromJson(Map<String, dynamic> json) {
    return Secret(
      id: json['id'],
      organizationId: json['organizationId'],
      projectId: json['projectId'],
      key: json['key'],
      value: json['value'],
      note: json['note'],
      creationDate: DateTime.parse(json['creationDate']),
      revisionDate: DateTime.parse(json['revisionDate']),
    );
  }
}

class SecretHeader {
  final String id;
  final String organizationId;
  final String key;

  SecretHeader({
    required this.id,
    required this.organizationId,
    required this.key,
  });

  factory SecretHeader.fromJson(Map<String, dynamic> json) {
    return SecretHeader(
      id: json['id'],
      organizationId: json['organizationId'],
      key: json['key'],
    );
  }
}

class Project {
  final String id;
  final String organizationId;
  final String name;
  final DateTime creationDate;
  final DateTime revisionDate;

  Project({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.creationDate,
    required this.revisionDate,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      organizationId: json['organizationId'],
      name: json['name'],
      creationDate: DateTime.parse(json['creationDate']),
      revisionDate: DateTime.parse(json['revisionDate']),
    );
  }
}
