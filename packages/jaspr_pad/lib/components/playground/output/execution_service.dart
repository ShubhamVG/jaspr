// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../adapters/html.dart';

final iframeProvider = StateProvider<IFrameElement?>((ref) => null);
final executionProvider = Provider<ExecutionService?>((ref) {
  var iframe = ref.watch(iframeProvider);
  if (iframe != null) return ExecutionService(iframe, ref);
  return null;
});
final consoleMessagesProvider = StateProvider<List<String>>((ref) => []);

class TestResult {
  final bool success;
  final List<String> messages;

  const TestResult(this.success, this.messages);
}

class ExecutionService {
  static const testKey = '__TESTRESULT__ ';

  final StreamController<TestResult> _testResultsController = StreamController<TestResult>.broadcast();

  final Ref ref;
  final IFrameElement _frame;
  IFrameElement get frame => _frame;
  final Completer<void> _readyCompleter = Completer();

  ExecutionService(this._frame, this.ref) {
    final src = _frame.src;
    if (src == null) {
      throw ('invalid iframe src');
    }

    _initListener();
  }

  Future<void> execute(
    String html,
    String css,
    String javaScript, {
    String? modulesBaseUrl,
    bool addRequireJs = false,
    bool addFirebaseJs = false,
    bool destroyFrame = false,
  }) async {
    return _send('execute', {
      'html': html,
      'css': css,
      'js': _decorateJavaScript(javaScript, modulesBaseUrl: modulesBaseUrl, requireFirebase: addFirebaseJs),
      'addRequireJs': addRequireJs,
      'addFirebaseJs': addFirebaseJs,
      'destroyFrame': destroyFrame,
    });
  }

  void replaceHtml(String html) {
    _send('setHtml', {'html': html});
  }

  void replaceCss(String css) {
    _send('setCss', {'css': css});
  }

  set frameSrc(String src) {
    _frame.src = src;
  }

  String get testResultDecoration => '''
void _result(bool success, [List<String> messages = const []]) {
  // Join messages into a comma-separated list for inclusion in the JSON array.
  final joinedMessages = messages.map((m) => '"\$m"').join(',');
  print('$testKey{"success": \$success, "messages": [\$joinedMessages]}');
}

// Ensure we have at least one use of `_result`.
var resultFunction = _result;

// Placeholder for unimplemented methods in dart-pad exercises.
// ignore: non_constant_identifier_names, sdk_version_never
Never TODO([String message = '']) => throw UnimplementedError(message);
''';

  String _decorateJavaScript(
    String javaScript, {
    required String? modulesBaseUrl,
    required bool requireFirebase,
  }) {
    final completeScript = StringBuffer();
    final usesRequireJs = modulesBaseUrl != null;
    // postMessagePrint:
    completeScript.writeln('''
var testKey = '$testKey';

function dartPrint(message) {
  if (message.startsWith(testKey)) {
    var resultMsg = JSON.parse(message.substring(testKey.length));
    resultMsg.sender = 'frame';
    resultMsg.type = 'testResult';
    parent.postMessage(resultMsg, '*');
  } else {
    parent.postMessage(
      {'sender': 'frame', 'type': 'stdout', 'message': message.toString()}, '*');
  }
}
''');
    if (usesRequireJs) {
      completeScript.writeln('''
// Unload previous version.
require.undef('dartpad_main');
''');
    }

    // The JavaScript exception handling for DartPad catches both errors
    // directly raised by `main()` (in which case we might have useful Dart
    // exception information we don't want to discard), as well as errors
    // generated by other means, like assertion errors when starting up
    // asynchronous functions.
    //
    // To avoid duplicating error messages on the DartPad console, we signal to
    // `window.onerror` that we've already sent a dartMainRunner message by
    // flipping _thrownDartMainRunner to true.  Some platforms don't populate
    // error so avoid using it if it is null.
    //
    // This seems to produce both the stack traces we expect in inspector and
    // the right error messages on the console.
    completeScript.writeln('''
var _thrownDartMainRunner = false;

window.onerror = function(message, url, lineNumber, colno, error) {
  if (!_thrownDartMainRunner) {
    var errorMessage = '';
    if (error != null) {
      errorMessage = 'Error: ' + error;
    } 
    parent.postMessage(
      {'sender': 'frame', 'type': 'stderr', 'message': message + errorMessage}, '*');
  }
  _thrownDartMainRunner = false;
};
''');

    if (usesRequireJs) {
      completeScript.writeln('''
require.config({
  "baseUrl": "$modulesBaseUrl",
  "waitSeconds": 60
});
''');
    }

    completeScript.writeln(javaScript);

    if (usesRequireJs) {
      completeScript.writeln('''
require(['dart_sdk'],
  function(sdk) {
    'use strict';
    sdk.developer._extensions.clear();
    sdk.dart.hotRestart();
});

require(["dartpad_main", "dart_sdk"], function(dartpad_main, dart_sdk) {
    // SDK initialization.
    dart_sdk.dart.setStartAsyncSynchronously(true);
    dart_sdk._isolate_helper.startRootIsolate(() => {}, []);

    // Loads the `dartpad_main` module and runs its bootstrapped main method.
    //
    // DDK provides the user's code in a RequireJS module, which exports an
    // object that looks something like this:
    //
    // {
    //       [random_tokens]__bootstrap: bootstrap,
    //       [random_tokens]__main: main
    // }
    //
    // The first of those properties holds the compiled code for the bootstrap
    // Dart file, which the server uses to wrap the user's code and wait on a
    // call to dart:ui's `webOnlyInitializePlatform` before executing any of it.
    //
    // The loop below iterates over the properties of the exported object,
    // looking for one that ends in "__bootstrap". Once found, it executes the
    // bootstrapped main method, which calls the user's main method, which
    // (presumably) calls runApp and starts Flutter's rendering.

    // TODO: simplify this once we are firmly in a post Flutter 1.24 world.
    for (var prop in dartpad_main) {
          if (prop.endsWith("bootstrap")) {
            dartpad_main[prop].main();
          }
    }});
''');
    }

    return completeScript.toString();
  }

  Stream<TestResult> get testResults => _testResultsController.stream;

  Future<void> _send(String command, Map<String, Object> params) {
    final message = {
      'command': command,
      ...params,
    };
    _frame.contentWindow!.postMessage(message, '*');
    return Future.value();
  }

  void _initListener() {
    window.addEventListener('message', (event) {
      if (event is MessageEvent) {
        final data = event.data;
        if (data['sender'] != 'frame') {
          return;
        }
        final type = data['type'] as String?;

        if (type == 'testResult') {
          _testResultsController
              .add(TestResult(data['success'] as bool, List<String>.from(data['messages'] as Iterable? ?? [])));
        } else if (type == 'stderr') {
          // Ignore any exceptions before the iframe has completed initialization.
          if (_readyCompleter.isCompleted) {
            // TODO error
            ref.read(consoleMessagesProvider.notifier).update((l) => [...l, data['message'] as String]);
          }
        } else if (type == 'ready' && !_readyCompleter.isCompleted) {
          _readyCompleter.complete();
        } else if (data['message'] != null) {
          ref.read(consoleMessagesProvider.notifier).update((l) => [...l, data['message'] as String]);
        }
      }
    }, false);
  }
}
