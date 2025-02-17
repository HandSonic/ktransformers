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
wget https://github.com/kvcache-ai/ktransformers/releases/download/v0.1.4/ktransformers-0.3.0rc0+cu126torch26fancy-cp311-cp311-linux_x86_64.whl &&
pip install ./ktransformers-0.3.0rc0+cu126torch26fancy-cp311-cp311-linux_x86_64.whl
EOF

ENTRYPOINT ["tail", "-f", "/dev/null"]