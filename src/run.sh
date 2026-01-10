#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  entrypoint.sh --binary /path/to/bedrock-server/bedrock_server --data /path/to/bedrock-data-dir

Required flags:
  --binary       Path to Bedrock server binary
  --data         Path to Bedrock server data dir
EOF
  exit 2
}

BINARY_PATH=""
DATA_DIR_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary)
      [[ $# -ge 2 ]] || usage
      BINARY_PATH="$2"
      shift 2
      ;;
    --binary=*)
      BINARY_PATH="${1#*=}"
      shift
      ;;
    --data)
      [[ $# -ge 2 ]] || usage
      DATA_DIR_PATH="$2"
      shift 2
      ;;
    --data=*)
      DATA_DIR_PATH="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

[[ -n "${BINARY_PATH}" && -n "${DATA_DIR_PATH}" ]] || usage

# Resolve absolute paths
if command -v realpath >/dev/null 2>&1; then
  BINARY_PATH="$(realpath "$BINARY_PATH")"
  DATA_DIR_PATH="$(realpath "$DATA_DIR_PATH")"
else
  # best-effort fallback
  BINARY_PATH="$(cd "$(dirname "$BINARY_PATH")" && pwd)/$(basename "$BINARY_PATH")"
  DATA_DIR_PATH="$(cd "$DATA_DIR_PATH" && pwd)"
fi

PROPERTIES_PATH="$DATA_DIR_PATH/server.properties"

declare -A PROPS=()

if [[ -f "$PROPERTIES_PATH" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == \#* ]] && continue
    [[ "$line" != *"="* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    PROPS["$key"]="$value"
  done < "$PROPERTIES_PATH"
fi

apply_env_overrides() {
  override_if_set() {
    local env_name="$1"
    local prop_key="$2"
    if [[ "${!env_name+x}" == "x" ]]; then
      PROPS["$prop_key"]="${!env_name}"
    fi
  }

  override_if_set SERVER_NAME "server-name"
  override_if_set GAMEMODE "gamemode"
  override_if_set FORCE_GAMEMODE "force-gamemode"
  override_if_set DIFFICULTY "difficulty"
  override_if_set ALLOW_CHEATS "allow-cheats"
  override_if_set MAX_PLAYERS "max-players"
  override_if_set ONLINE_MODE "online-mode"
  override_if_set ALLOW_LIST "allow-list"
  override_if_set SERVER_PORT "server-port"
  override_if_set SERVER_PORT_V6 "server-port-v6"
  override_if_set ENABLE_LAN_VISIBILITY "enable-lan-visibility"
  override_if_set VIEW_DISTANCE "view-distance"
  override_if_set TICK_DISTANCE "tick-distance"
  override_if_set PLAYER_IDLE_TIMEOUT "player-idle-timeout"
  override_if_set MAX_THREADS "max-threads"
  override_if_set LEVEL_NAME "level-name"
  override_if_set LEVEL_SEED "level-seed"
  override_if_set DEFAULT_PLAYER_PERMISSION_LEVEL "default-player-permission-level"
  override_if_set TEXTUREPACK_REQUIRED "texturepack-required"
  override_if_set CONTENT_LOG_FILE_ENABLED "content-log-file-enabled"
  override_if_set CONTENT_LOG_CONSOLE_OUTPUT_ENABLED "content-log-console-output-enabled"
  override_if_set CONTENT_LOG_LEVEL "content-log-level"
  override_if_set COMPRESSION_THRESHOLD "compression-threshold"
  override_if_set COMPRESSION_ALGORITHM "compression-algorithm"
  override_if_set SERVER_AUTHORITATIVE_MOVEMENT "server-authoritative-movement"
  override_if_set SERVER_AUTHORITATIVE_DISMOUNT "server-authoritative-dismount"
  override_if_set SERVER_AUTHORITATIVE_ENTITY_INTERACTIONS_STRICT "server-authoritative-entity-interactions-strict"
  override_if_set PLAYER_POSITION_ACCEPTANCE_THRESHOLD "player-position-acceptance-threshold"
  override_if_set PLAYER_MOVEMENT_ACTION_DIRECTION_THRESHOLD "player-movement-action-direction-threshold"
  override_if_set SERVER_AUTHORITATIVE_BLOCK_BREAKING_PICK_RANGE_SCALAR "server-authoritative-block-breaking-pick-range-scalar"
  override_if_set CHAT_RESTRICTION "chat-restriction"
  override_if_set DISABLE_PLAYER_INTERACTION "disable-player-interaction"
  override_if_set CLIENT_SIDE_CHUNK_GENERATION_ENABLED "client-side-chunk-generation-enabled"
  override_if_set BLOCK_NETWORK_IDS_ARE_HASHES "block-network-ids-are-hashes"
  override_if_set DISABLE_PERSONA "disable-persona"
  override_if_set DISABLE_CUSTOM_SKINS "disable-custom-skins"
  override_if_set SERVER_BUILD_RADIUS_RATIO "server-build-radius-ratio"
  override_if_set ALLOW_OUTBOUND_SCRIPT_DEBUGGING "allow-outbound-script-debugging"
  override_if_set ALLOW_INBOUND_SCRIPT_DEBUGGING "allow-inbound-script-debugging"
  override_if_set SCRIPT_DEBUGGER_AUTO_ATTACH "script-debugger-auto-attach"
}

if ! (
  apply_env_overrides

  tmp="$(mktemp)"
  for k in "${!PROPS[@]}"; do
    printf '%s=%s\n' "$k" "${PROPS[$k]}"
  done > "$tmp"

  mv -f "$tmp" "$PROPERTIES_PATH"
); then
  echo "Error loading server properties: failed to update $PROPERTIES_PATH" >&2
fi

export LD_LIBRARY_PATH="$DATA_DIR_PATH"

chmod 0755 "$BINARY_PATH" || true

cd "$DATA_DIR_PATH"
exec "$BINARY_PATH"
