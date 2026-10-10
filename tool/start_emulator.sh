#!/usr/bin/env bash
# Кирилл: поднимает эмулятор перед F5 в VS Code (см. .vscode/tasks.json).
# Если устройство уже подключено - ничего не делает
set -euo pipefail

AVD_NAME="${SLOTLY_AVD:-slotly_api36}"
PORT=5554
SERIAL="emulator-$PORT"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$SDK" ]; then
  SDK="$(flutter config --list 2>/dev/null | sed -n 's/^ *android-sdk: //p')"
fi
SDK="${SDK:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"

if "$ADB" devices | grep -q "^$SERIAL[[:space:]]*device"; then
  echo "Emulator $SERIAL is already running."
  exit 0
fi

echo "Starting emulator $AVD_NAME on $SERIAL..."
LOG="${TMPDIR:-/tmp}/slotly_emulator.log"
nohup "$EMULATOR" -avd "$AVD_NAME" -port "$PORT" >"$LOG" 2>&1 &
EMULATOR_PID=$!

until [ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  if ! kill -0 "$EMULATOR_PID" 2>/dev/null; then
    echo "Emulator exited unexpectedly. Log: $LOG" >&2
    tail -n 20 "$LOG" >&2
    exit 1
  fi
  sleep 2
done
echo "Emulator $SERIAL is ready."
