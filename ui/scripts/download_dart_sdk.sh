#!/usr/bin/env bash
set -euo pipefail

# Defaults
BSR="buf.build"
ORG="antinvestor"
TMP_TAR="sdk.tar.gz"
SDK_VERSION="latest"
OUT_DIR="/tmp/dart/sdks"
LANGUAGE="dart"

MODULE=""
PLUGIN=""

usage() {
  cat <<EOF
Usage:
  ./download_sdk.sh --module <module> --language <lang> --plugin <plugin> --out <directory> [--org <org>] [--no-replace]

Required:
  --module <module>         Buf module name (e.g., chat)
  --language <language>     Language folder (e.g., dart, go)
  --plugin <plugin>         Plugin/framework (e.g., protocolbuffers, connectrpc, grpc)
  --out <directory>         Output directory for the SDK

Optional:
  --org <org>               Buf organization (default: antinvestor)
  --version <version>       SDK version (default: latest)
  --help                    Show help

Example:
  ./download_sdk.sh --module chat --language dart --plugin protocolbuffers --out ./dart-sdk
EOF
  exit 1
}

#
# Parse CLI options
#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --module)
      MODULE="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --plugin)
      PLUGIN="$2"
      shift 2
      ;;
    --out)
      OUT_DIR="$2"
      shift 2
      ;;
    --org)
      ORG="$2"
      shift 2
      ;;
    --version)
      SDK_VERSION="$2"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

#
# Validate required args
#
[[ -z "$MODULE" ]] && echo "ERROR: --module is required" && usage
[[ -z "$LANGUAGE" ]] && echo "ERROR: --language is required" && usage
[[ -z "$PLUGIN" ]] && echo "ERROR: --plugin is required" && usage
[[ -z "$OUT_DIR" ]] && echo "ERROR: --out is required" && usage

echo "Config:"
echo "  ORG:      ${ORG}"
echo "  MODULE:   ${MODULE}"
echo "  LANGUAGE: ${LANGUAGE}"
echo "  PLUGIN:   ${PLUGIN}"
echo "  OUT_DIR:  ${OUT_DIR}"
echo "  VERSION:  ${SDK_VERSION}"
echo

#
# Build archive URL (.tar.gz)
#
ARCHIVE_URL="https://${BSR}/gen/archive/${ORG}/${MODULE}/${PLUGIN}/${LANGUAGE}/${SDK_VERSION}.tar.gz?imports=true&wkt=true"

echo "Downloading from:"
echo "  ${ARCHIVE_URL}"
echo

curl -fsSL -o "${TMP_TAR}" "${ARCHIVE_URL}"

#
# Extract
#
echo "Extracting into $OUT_DIR …"
mkdir -p "${OUT_DIR}"
tar -xzf "${TMP_TAR}" -C "${OUT_DIR}"

rm "${TMP_TAR}"

cp -Rf "${OUT_DIR}/${MODULE}_${LANGUAGE}/." "../lib/apis/"

echo
echo "Done — Installed SDK version: ${SDK_VERSION}"
echo "Location: ${OUT_DIR}"
