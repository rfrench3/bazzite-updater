#!/usr/bin/env bash
#
# Adapted from vermouth: https://github.com/dekomote/vermouth/blob/master/po/update-pot.sh

set -euo pipefail

BASEDIR=$(cd "$(dirname "$0")/.." && pwd)

cd $BASEDIR
POTFILE="po/bazzite-updater.pot"

COMMON_ARGS=(
    --from-code=UTF-8
    -ci18n
    -ki18n:1
    -ki18nc:1c,2
    -ki18np:1,2
    -ki18ncp:1c,2,3
    -ktr2i18n:1
    -kI18N_NOOP:1
    -kI18N_NOOP2:1c,2
    -kaliasLocale
    -kki18n:1
    -kki18nc:1c,2
    -kki18np:1,2
    -kki18ncp:1c,2,3
    --package-name=bazzite-updater
)

echo "Updating potfile..."
find "src" \( -name "*.cpp" -o -name "*.h" \) | sort | \
xgettext --files-from=- \
    -C \
    "${COMMON_ARGS[@]}" \
    --output="$POTFILE"

find "src" -name "*.qml" | sort | \
xgettext --files-from=- \
    --language=JavaScript \
    "${COMMON_ARGS[@]}" \
    --join-existing \
    --output="$POTFILE"

echo "Updating pofiles..."
for po in "$BASEDIR"/po/*/bazzite-updater.po; do
    msgmerge -U "$po" "$POTFILE"
done

echo "Done."
