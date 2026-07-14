#!/usr/bin/env bash
# Flattens manifest.json into (distro, php, version) rows - including a
# synthetic "base" row per PHP version - and filters them by whichever
# distro/php/version tokens are passed in. Any dimension with no matching
# token is treated as a wildcard (matches everything).
#
# Token classification:
#   magento | mage-os | mageos   -> distro filter
#   php<glob>                    -> php filter (prefix stripped, e.g. php8.* -> 8.*)
#   anything else                -> version filter (glob)
#
# Usage: scripts/filter-matrix.sh [tokens...]
#   scripts/filter-matrix.sh magento 2.4.9 8.5
#   scripts/filter-matrix.sh php8.5
#   scripts/filter-matrix.sh mage-os
#   scripts/filter-matrix.sh magento 2.4.8-p*
#
# Outputs a single JSON object on stdout:
#   {"matrix-base":{"php":[...]},"matrix-magento":{"include":[...]},"matrix-mageos":{"include":[...]}}

set -e

MANIFEST="${MANIFEST:-manifest.json}"
[ ! -f "$MANIFEST" ] && echo "manifest.json not found" >&2 && exit 1

DISTRO_FILTERS=()
PHP_FILTERS=()
VERSION_FILTERS=()

for TOKEN in "$@"; do
  case "$TOKEN" in
    magento)
      DISTRO_FILTERS+=("magento")
      ;;
    mage-os|mageos)
      DISTRO_FILTERS+=("mage-os")
      ;;
    php*)
      PHP_FILTERS+=("${TOKEN#php}")
      ;;
    *)
      VERSION_FILTERS+=("$TOKEN")
      ;;
  esac
done

matches_any() {
  local value=$1
  shift
  local patterns=("$@")
  [ ${#patterns[@]} -eq 0 ] && return 0
  for pattern in "${patterns[@]}"; do
    case "$value" in
      $pattern) return 0 ;;
    esac
  done
  return 1
}

MATCHED_ROWS=()
while IFS=$'\t' read -r DISTRO PHP VERSION; do
  matches_any "$DISTRO" "${DISTRO_FILTERS[@]}" || continue
  matches_any "$PHP" "${PHP_FILTERS[@]}" || continue
  if [ "$DISTRO" != "base" ]; then
    matches_any "$VERSION" "${VERSION_FILTERS[@]}" || continue
  fi
  MATCHED_ROWS+=("$DISTRO"$'\t'"$PHP"$'\t'"$VERSION")
done < <(jq -r '
  to_entries[] as $e |
  ($e.key) as $php |
  ["base", $php, ""],
  ($e.value.magento[]? | ["magento", $php, .]),
  ($e.value."mage-os"[]? | ["mage-os", $php, .])
  | @tsv
' "$MANIFEST")

if [ ${#MATCHED_ROWS[@]} -eq 0 ]; then
  echo '{"matrix-base":{"php":[]},"matrix-magento":{"include":[]},"matrix-mageos":{"include":[]}}'
  exit 0
fi

printf '%s\n' "${MATCHED_ROWS[@]}" | jq -R -s -c '
  split("\n") | map(select(length > 0) | split("\t")) as $rows
  | {
      "matrix-base": { php: ($rows | map(.[1]) | unique) },
      "matrix-magento": { include: ($rows | map(select(.[0] == "magento") | {php: .[1], version: .[2]})) },
      "matrix-mageos": { include: ($rows | map(select(.[0] == "mage-os") | {php: .[1], version: .[2]})) }
    }
'
