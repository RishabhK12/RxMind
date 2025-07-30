#!/bin/bash
# Migration script: Move code/assets/config from medilab-prokit to rxmind (one-shot, no manual steps)
# Usage: bash migrate_medilab_to_rxmind.sh

set -e

SRC="medilab-prokit"
DEST="rxmind"

# 1. Copy Dart code
rm -rf "$DEST/lib"
cp -r "$SRC/lib" "$DEST/lib"

# 2. Copy tests
rm -rf "$DEST/test"
if [ -d "$SRC/test" ]; then
  cp -r "$SRC/test" "$DEST/test"
fi

# 3. Copy images and assets
if [ -d "$SRC/images" ]; then
  mkdir -p "$DEST/images"
  cp -r "$SRC/images" "$DEST/images"
fi
if [ -d "$SRC/assets" ]; then
  mkdir -p "$DEST/assets"
  cp -r "$SRC/assets" "$DEST/assets"
fi

# 4. Copy .env and config files if present
if [ -f "$SRC/.env" ]; then
  cp "$SRC/.env" "$DEST/.env"
fi
if [ -f "$SRC/.env.example" ]; then
  cp "$SRC/.env.example" "$DEST/.env.example"
fi

# 5. Copy pubspec.yaml (overwrites new one)
cp "$SRC/pubspec.yaml" "$DEST/pubspec.yaml"

# 6. Copy additional config files
for f in analysis_options.yaml .gitignore; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$DEST/$f"
  fi
done

cat <<EOF
Migration complete!
- Dart code, tests, images, assets, and config files have been copied to $DEST
- pubspec.yaml has been replaced (review and merge if needed)
- If you have custom native code in $SRC/android/app/src/main or $SRC/ios/Runner, manually merge it into $DEST/android/app/src/main and $DEST/ios/Runner. Do NOT overwrite the new project structure.

Next steps:
  cd $DEST
  flutter pub get
  flutter run
EOF
