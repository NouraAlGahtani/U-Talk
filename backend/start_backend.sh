#!/bin/zsh
# Starts the U-TALK backend (qwen3 replies + Andrew voice from Azure).
# Put this file in the backend folder (next to main.py) and run:  ./start_backend.sh
#
# ONE-TIME SETUP: store the Azure Speech key in the macOS Keychain (it will ask you to paste it;
# nothing is saved in shell history or in this file):
#     security add-generic-password -a "$USER" -s utalk-azure-speech -w
#
# Set REGION to the "Location/Region" code shown in Azure Portal -> your Speech resource -> Keys and Endpoint.

REGION="eastus"

cd "$(dirname "$0")" || exit 1

if [[ ! -f main.py ]]; then
  echo "main.py not found. Put start_backend.sh in the backend folder."
  exit 1
fi

KEY=$(security find-generic-password -a "$USER" -s utalk-azure-speech -w 2>/dev/null)
if [[ -z "$KEY" ]]; then
  echo "No Azure key in Keychain, so Andrew's voice will not work (the app falls back to the iPhone voice)."
  echo "Add it once with:  security add-generic-password -a \"\$USER\" -s utalk-azure-speech -w"
else
  export AZURE_SPEECH_KEY="$KEY"
  export AZURE_SPEECH_REGION="$REGION"
  echo "Azure Speech: key loaded from Keychain, region $REGION"
fi

source .venv/bin/activate || { echo "Could not activate .venv"; exit 1; }

if lsof -nP -iTCP:8000 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port 8000 is already in use (an old server?). Stop it with:  lsof -ti tcp:8000 | xargs kill"
  exit 1
fi

IP=$(ipconfig getifaddr en0)
echo "Mac IP: ${IP:-unknown}  ->  Conversation.swift baseURL must be http://${IP:-<ip>}:8000"
echo "iPhone test: open http://${IP:-<ip>}:8000/health in Safari"
echo

exec uvicorn main:app --host 0.0.0.0 --port 8000
