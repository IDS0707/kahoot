#!/usr/bin/env sh
set -eu

if [ ! -d .flutter ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git .flutter
fi

export PATH="$PWD/.flutter/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run
