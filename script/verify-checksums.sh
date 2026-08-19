#!/usr/bin/env bash
# Verify every SHA256 the formula declares against the checksums.txt published
# with the matching GitHub release.
#
# Why this exists: `brew test` and `brew install` only ever exercise the runner's
# own platform. This formula ships darwin/linux x amd64/arm64, so an
# install-and-run gate covers exactly one of four declared checksums and the
# other three are asserted but never checked. This closes that gap for all of
# them in one place.
set -euo pipefail

formula="${1:-rackctl.rb}"

if [[ ! -f "${formula}" ]]; then
  echo "formula not found: ${formula}" >&2
  exit 1
fi

version="$(sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p' "${formula}" | head -1)"
if [[ -z "${version}" ]]; then
  echo "could not parse a version from ${formula}" >&2
  exit 1
fi

# Pair each url with the sha256 that follows it. GoReleaser emits them adjacent
# and in that order, one pair per platform block.
declared="$(awk '
  /^[[:space:]]*url "/ {
    split($0, a, "\""); u = a[2]; sub(/.*\//, "", u); next
  }
  /^[[:space:]]*sha256 "/ {
    if (u == "") next
    split($0, a, "\""); print u, a[2]; u = ""
  }
' "${formula}")"

# An unparseable formula must fail loudly rather than verify zero artifacts and
# report success — a silent no-op here is indistinguishable from a clean pass.
if [[ -z "${declared}" ]]; then
  echo "no url/sha256 pairs found in ${formula} — unparseable or shape changed" >&2
  exit 1
fi

published="$(mktemp)"
trap 'rm -f "${published}"' EXIT

checksums_url="https://github.com/rackctl/rackctl/releases/download/v${version}/checksums.txt"
echo "fetching ${checksums_url}"
curl -fsSL "${checksums_url}" -o "${published}"

failed=0
count=0
while read -r artifact sha; do
  if [[ -z "${artifact}" ]]; then
    continue
  fi
  count=$((count + 1))
  expected="$(awk -v want="${artifact}" '$2 == want { print $1 }' "${published}")"
  if [[ -z "${expected}" ]]; then
    echo "FAIL ${artifact}: absent from the published checksums.txt" >&2
    failed=1
  elif [[ "${expected}" != "${sha}" ]]; then
    echo "FAIL ${artifact}: formula has ${sha}, release published ${expected}" >&2
    failed=1
  else
    echo "ok   ${artifact}"
  fi
done <<<"${declared}"

if [[ "${count}" -eq 0 ]]; then
  echo "verified no artifacts — refusing to report success" >&2
  exit 1
fi

if [[ "${failed}" -ne 0 ]]; then
  echo "checksum verification FAILED" >&2
  exit 1
fi

echo "all ${count} declared checksums match the published release"
