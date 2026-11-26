#!/usr/bin/env sh
set -eu
flutter create --platforms=android,ios,web,windows,macos,linux .
flutter pub get
dart run flutter_launcher_icons
