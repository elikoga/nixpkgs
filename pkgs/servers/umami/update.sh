#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl common-updater-scripts nodePackages.node2nix gnused nix coreutils jq

set -euo pipefail

latestVersion="$(curl -s "https://api.github.com/repos/mikecao/umami/releases?per_page=1" | jq -r ".[0].tag_name" | sed 's/^v//')"
currentVersion=$(nix-instantiate --eval -E "with import ./. {}; umami.version or (lib.getVersion umami)" | tr -d '"')

if [[ "$currentVersion" == "$latestVersion" ]]; then
  echo "umami is up-to-date: $currentVersion"
  exit 0
fi

update-source-version umami 0 sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
update-source-version umami "$latestVersion"

# use patched source
store_src="$(nix-build . -A umami.src --no-out-link)"

cd "$(dirname "${BASH_SOURCE[0]}")"

yarn2nix \
  --lockfile="$store_src/yarn.lock" \
  > yarn.nix
