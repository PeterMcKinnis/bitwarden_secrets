import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Define the types for the C functions
typedef InitFunc = Pointer<Void> Function(Pointer<Utf8> clientSettings);
typedef RunCommandFunc = Pointer<Utf8> Function(
    Pointer<Utf8> command, Pointer<Void> client);
typedef FreeMemFunc = Void Function(Pointer<Void> client);
typedef FreeMemFuncDart = void Function(Pointer<Void> client);

class BitwardenClient {
  BitwardenClient._(this._freeMem, this._runCommand, this.clientPtr);

  final FreeMemFuncDart _freeMem;
  final RunCommandFunc _runCommand;
  Pointer<Void> clientPtr;

  factory BitwardenClient(
      DynamicLibrary bitwardenLib, BitwardenClientSettings settings) {
    InitFunc init =
        bitwardenLib.lookup<NativeFunction<InitFunc>>('init').asFunction();
    FreeMemFuncDart freeMem = bitwardenLib
        .lookup<NativeFunction<FreeMemFunc>>('free_mem')
        .asFunction();
    RunCommandFunc runCommand = bitwardenLib
        .lookup<NativeFunction<RunCommandFunc>>('run_command')
        .asFunction();

    final clientSettingsPtr = jsonEncode(settings.toJson()).toNativeUtf8();
    final clientPtr = init(clientSettingsPtr);
    malloc.free(clientSettingsPtr);
    if (clientPtr.address == 0) {
      throw Exception('Initialization failed');
    }
    return BitwardenClient._(freeMem, runCommand, clientPtr);
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
  String deviceType;

  // toJson function
  Map<String, dynamic> toJson() {
    return {
      if (apiUrl != null) 'apiUrl': apiUrl,
      if (identityUrl != null) 'identityUrl': identityUrl,
      'userAgent': userAgent,
      'deviceType': deviceType,
    };
  }
}
