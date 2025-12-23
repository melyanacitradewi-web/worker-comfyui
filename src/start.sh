#!/usr/bin/env bash

# Create symlinks from network volume
VOLUME_PATH="/runpod-volume/runpod-slim/ComfyUI"

# Link custom nodes
if [ -d "$VOLUME_PATH/custom_nodes" ]; then
    echo "Linking custom nodes from network volume..."
    rm -rf /comfyui/custom_nodes
    ln -s $VOLUME_PATH/custom_nodes /comfyui/custom_nodes
fi

# Link models folder
if [ -d "$VOLUME_PATH/models" ]; then
    echo "Linking models from network volume..."
    rm -rf /comfyui/models
    ln -s $VOLUME_PATH/models /comfyui/models
fi

# Link input folder
if [ -d "$VOLUME_PATH/input" ]; then
    echo "Linking input folder from network volume..."
    rm -rf /comfyui/input
    ln -s $VOLUME_PATH/input /comfyui/input
fi

# Link output folder
if [ -d "$VOLUME_PATH/output" ]; then
    echo "Linking output folder from network volume..."
    rm -rf /comfyui/output
    ln -s $VOLUME_PATH/output /comfyui/output
fi

echo "Network volume setup complete!"

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi
