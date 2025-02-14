FROM node:20.16.0 as web_compile
WORKDIR /home
RUN <<EOF
git clone https://github.com/kvcache-ai/ktransformers.git &&
cd ktransformers/ktransformers/website/ &&
npm install @vue/cli &&
npm run build &&
rm -rf node_modules
EOF



FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel as compile_server
#FROM ubuntu:20.04 as compile_server
WORKDIR /workspace
ENV CUDA_HOME /usr/local/cuda
COPY --from=web_compile /home/ktransformers /workspace/ktransformers
RUN <<EOF
apt update -y &&  apt install -y  --no-install-recommends \
    git \
    wget \
    vim \
    gcc \
    g++ \
    cmake &&
rm -rf /var/lib/apt/lists/* &&
cd ktransformers &&
git submodule init &&
git submodule update &&
pip install ninja pyproject numpy cpufeature &&
pip install flash-attn &&
CPU_INSTRUCT=NATIVE  KTRANSFORMERS_FORCE_BUILD=TRUE TORCH_CUDA_ARCH_LIST="8.0;8.6;8.7;8.9;9.0+PTX" pip install . --no-build-isolation --verbose &&
pip cache purge
EOF
RUN ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/conda/lib/python3.10/site-packages/torch/lib/../../../.././libstdc++.so.6

#ENTRYPOINT [ "/opt/conda/bin/ktransformers" ]