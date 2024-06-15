import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Define the path to the shared library
final DynamicLibrary bitwardenLib = Platform.isWindows
    ? DynamicLibrary.open('native/bitwarden_c.dll')
    : throw Exception("non-windows not supported");

// Define the types for the C functions
typedef InitFunc = Pointer<Void> Function(Pointer<Utf8> clientSettings);
typedef RunCommandFunc = Pointer<Utf8> Function(
    Pointer<Utf8> command, Pointer<Void> client);

// Create Dart function pointers for the C functions
final InitFunc _init =
    bitwardenLib.lookup<NativeFunction<InitFunc>>('init').asFunction();
final RunCommandFunc _runCommand = bitwardenLib
    .lookup<NativeFunction<RunCommandFunc>>('run_command')
    .asFunction();

typedef FreeMemFunc = Void Function(Pointer<Void> client);
typedef FreeMemFuncDart = void Function(Pointer<Void> client);
final FreeMemFuncDart _freeMem = bitwardenLib
    .lookup<NativeFunction<FreeMemFunc>>('free_mem')
    .asFunction<FreeMemFuncDart>();

class BitwardenClient {
  Pointer<Void> clientPtr;

  BitwardenClient._(this.clientPtr);

  factory BitwardenClient(BitwardenClientSettings settings) {
    final clientSettingsPtr = jsonEncode(settings.toJson()).toNativeUtf8();
    final clientPtr = _init(clientSettingsPtr);
    malloc.free(clientSettingsPtr);
    if (clientPtr.address == 0) {
      throw Exception('Initialization failed');
    }
    return BitwardenClient._(clientPtr);
  }

  String runCommand(String command) {
    final commandPtr = command.toNativeUtf8();
    final resultPtr = _runCommand(commandPtr, clientPtr);
    malloc.free(commandPtr);
    if (resultPtr.address == 0) {
      throw Exception('Run command failed');
    }
    final result = resultPtr.toDartString();
    malloc.free(resultPtr);
    print(result);
    return result;
  }

  void free() {
    _freeMem(clientPtr);
  }
}

class BitwardenClientSettings {
  // Constructor
  BitwardenClientSettings({
    required this.apiUrl,
    required this.identityUrl,
    required this.userAgent,
    required this.deviceType,
  });

  /// Use null for default
  String? apiUrl;

  /// Use null for default
  String? identityUrl;
  String userAgent;
  int deviceType;

  // toJson function
  Map<String, dynamic> toJson() {
    return {
      'apiUrl': apiUrl,
      'identityUrl': identityUrl,
      'userAgent': userAgent,
      'deviceType': deviceType,
    };
  }
}


