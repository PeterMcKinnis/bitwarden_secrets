import 'dart:convert';
import 'dart:ffi';
import 'package:bitwarden_secrets/src/client.dart';

// See
// https://github.com/bitwarden/sdk/blob/32ac1e477a5578ac039031c76920bc295fbc1c38/crates/bitwarden-api-api/src/models/device_type.rs
const int bwsWindowsDesktopDeviceType = 6;

/// The main class used to authenticate, query, and edit Bitwarden Secrets objects
class BitwardenSecrets {
  BitwardenSecrets(String organizationId, DynamicLibrary bitwardenLib,
      {String? identityUrl, String? apiUrl})
      : _organizationId = organizationId,
        _client = BitwardenClient(
            bitwardenLib,
            BitwardenClientSettings(
                apiUrl: apiUrl,
                identityUrl: identityUrl,
                userAgent: "Bitwarden DART-SDK",
                deviceType: "SDK"));

  final BitwardenClient _client;
  final String _organizationId;

  /// Logs in using an access token.  Access token can be generated using the bitwarden web valut.  https://vault.bitwarden.com/
  /// Note that this function may return successfully even with a bad or expired accessToken.  Use projectList or similar to
  /// ensure credentials are working
  AccessTokenLoginResponse accessTokenLogin(String accessToken,
      {String? statePath}) {
    var command = {
      "accessTokenLogin": {
        "accessToken": accessToken,
        "stateFile": statePath,
      }
    };

    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return AccessTokenLoginResponse.fromJson(json);
  }

  Map<String, dynamic> _checkResponse(String raw) {
    var response = _Response.fromJson(jsonDecode(raw));
    if (response.success) {
      return response.data!;
    } else {
      throw Exception("bitwarden client error: ${response.errorMessage}");
    }
  }

  /// Create a secret
  /// As of 6/16/2024 new secrets may not have multiple projectIds
  Secret secretCreate(String key, String value, String projectId,
      {String? note}) {
    var command = {
      "secrets": {
        "create": {
          "organizationId": _organizationId,
          "key": key,
          "value": value,
          "projectIds": [projectId],
          "note": note ?? ""
        }
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Secret.fromJson(json);
  }

  /// Delete multiple secrets
  void secretDelete(List<String> secretIds) {
    var command = {
      "secrets": {
        "delete": {"ids": secretIds}
      }
    };
    _checkResponse(_client.runCommand(jsonEncode(command)));
  }

  /// Update a secret.  A null arguement for key, value, note, or project id will cause the existing value to be retained.
  Secret secretEdit(Secret secret,
      {String? key, String? value, String? note, String? projectId}) {
    var command = {
      "secrets": {
        "update": {
          "id": secret.id,
          "organizationId": secret.organizationId,
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

  // Lookup secret details
  Secret secretGet(String secretId) {
    var command = {
      "secrets": {
        "get": {"id": secretId}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Secret.fromJson(json);
  }

  // Lookup secret details
  List<Secret> secretGetByIds(List<String> secretIds) {
    var command = {
      "secrets": {
        "get": {"ids": secretIds}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return (json["data"] as List<dynamic>)
        .map((e) => Secret.fromJson(e))
        .toList();
  }

  /// Lookup all secrets.  Note only the SecretIdentifier is returned.  Use [secretGet] to retrieve the value and other details.
  List<SecretIdentifier> secretList() {
    var command = {
      "secrets": {
        "list": {"organizationId": _organizationId}
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return (json["data"])
        .map<SecretIdentifier>((e) => SecretIdentifier.fromJson(e))
        .toList();
  }

  /// Creat a project
  Project projectCreate(String name) {
    var command = {
      "projects": {
        "create": {"name": name, "organizationId": _organizationId}
      }
    };

    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Project.fromJson(json);
  }

  /// Delete multiple projects
  void projectDelete(List<String> projectIds) {
    var command = {
      "projects": {
        "delete": {
          "ids": projectIds,
        }
      }
    };
    _checkResponse(_client.runCommand(jsonEncode(command)));
  }

  /// Update the name of a project
  Project projectEdit(Project project, {String? name}) {
    var command = {
      "projects": {
        "update": {
          "organizationId": _organizationId,
          "id": project.id,
          "name": name ?? project.name,
        }
      }
    };
    var json = _checkResponse(_client.runCommand(jsonEncode(command)));
    return Project.fromJson(json);
  }

  /// Lookup a project
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

  /// List all projects
  List<Project> projectList() {
    var command = {
      "projects": {
        "list": {"organizationId": _organizationId}
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

/// The result of several Bitwarden Secrets queries such as [SessionGet] and [SessionList]
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

class SecretIdentifier {
  final String id;
  final String organizationId;
  final String key;

  SecretIdentifier({
    required this.id,
    required this.organizationId,
    required this.key,
  });

  factory SecretIdentifier.fromJson(Map<String, dynamic> json) {
    return SecretIdentifier(
      id: json['id'],
      organizationId: json['organizationId'],
      key: json['key'],
    );
  }
}

/// The result of several Bitwarden Project queries such as [ProjectGet] and [ProjectList]
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

/// Holds the response to [AuthTokenLogin]
class AccessTokenLoginResponse {
  AccessTokenLoginResponse({
    required this.authenticated,
    required this.resetMasterPassword,
    required this.forcePasswordReset,
    required this.twoFactor,
  });

  bool authenticated;
  bool resetMasterPassword;
  bool forcePasswordReset;
  Object? twoFactor;

  factory AccessTokenLoginResponse.fromJson(Map<String, dynamic> json) {
    return AccessTokenLoginResponse(
      authenticated: json['authenticated'],
      resetMasterPassword: json['resetMasterPassword'],
      forcePasswordReset: json['forcePasswordReset'],
      twoFactor: json['twoFactor'],
    );
  }
}
