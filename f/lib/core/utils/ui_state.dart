import 'package:flutter/foundation.dart';

/// Tiny app-wide UI flags that more than one widget needs to react to.
class UiState {
  UiState._();

  /// True while the editor is in full-screen mode. [RootShell] listens to
  /// this to hide the bottom navigation bar.
  static final ValueNotifier<bool> editorFullscreen = ValueNotifier<bool>(false);
}
