# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.10.0-base

# build-time tokens for gated downloads are read from BuildKit secret
# mounts — they are never written to a layer or to image history.
# pass via: docker buildx build --secret id=hf_token,env=HF_TOKEN .

# install custom nodes into comfyui
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && cd /comfyui/custom_nodes/ComfyUI-KJNodes && (git checkout e27a505b3ba6ce42687fe00500deda103d9d6071 2>/dev/null || (git fetch origin e27a505b3ba6ce42687fe00500deda103d9d6071 --depth=1 && git checkout e27a505b3ba6ce42687fe00500deda103d9d6071) || echo "WARN: commit e27a505b3ba6ce42687fe00500deda103d9d6071 unreachable in https://github.com/kijai/ComfyUI-KJNodes, falling back to default branch HEAD")
RUN git clone https://github.com/lonecatone23/ComfyUI_LC123_nodes /comfyui/custom_nodes/ComfyUI_LC123_nodes && cd /comfyui/custom_nodes/ComfyUI_LC123_nodes && (git checkout ba9567ec35f8ddd8576020e6102116340dcbd446 2>/dev/null || (git fetch origin ba9567ec35f8ddd8576020e6102116340dcbd446 --depth=1 && git checkout ba9567ec35f8ddd8576020e6102116340dcbd446) || echo "WARN: commit ba9567ec35f8ddd8576020e6102116340dcbd446 unreachable in https://github.com/lonecatone23/ComfyUI_LC123_nodes, falling back to default branch HEAD")
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && cd /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && (git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca 2>/dev/null || (git fetch origin d78b780ae43fcf8c6b7c6505e6ffb4584281ceca --depth=1 && git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca) || echo "WARN: commit d78b780ae43fcf8c6b7c6505e6ffb4584281ceca unreachable in https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail rgthree-comfy@1.0.2604070017 --mode remote || (echo "WARN: rgthree-comfy@1.0.2604070017 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail rgthree-comfy --mode remote)
RUN git clone https://github.com/lonecatone23/ComfyUI_LC_Vision_nodes /comfyui/custom_nodes/ComfyUI_LC_Vision_nodes && cd /comfyui/custom_nodes/ComfyUI_LC_Vision_nodes && (git checkout 78fb52dbbe07c8e4a8e61a569680473e6c1d9934 2>/dev/null || (git fetch origin 78fb52dbbe07c8e4a8e61a569680473e6c1d9934 --depth=1 && git checkout 78fb52dbbe07c8e4a8e61a569680473e6c1d9934) || echo "WARN: commit 78fb52dbbe07c8e4a8e61a569680473e6c1d9934 unreachable in https://github.com/lonecatone23/ComfyUI_LC_Vision_nodes, falling back to default branch HEAD")
# RUN # Could not resolve custom node: LCNote
# RUN # Could not resolve custom node: LCImageLabel

# download models into comfyui
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/unsloth/FLUX.2-VAE/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/Unknown --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/
