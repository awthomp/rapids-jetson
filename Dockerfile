#
# NOTE: This Dockerfile was created to facilitate building
#       cuDF inside of a docker container on a Jetson
#
# 9/26/19 JTichy -- First try

FROM nvcr.io/nvidia/l4t-base:r32.2.1 AS build

MAINTAINER Jason Tichy version: 0.1

# Dangerous copies, locks build to specific device, but needed to compile cuda code in Dockerfile
COPY cuda_libs/lib64/libcublas.so /usr/local/cuda-10.0/lib64
COPY cuda_libs/lib64/libcudart.so /usr/local/cuda-10.0/lib64
COPY cuda_libs/lib64/libcufft.so /usr/local/cuda-10.0/lib64

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
            python3-dev python3-pip python3-virtualenv llvm-7-dev \
            libprotobuf-dev libprotoc-dev protobuf-compiler thrift-compiler \
            libboost-all-dev libcurl4-openssl-dev libssl-dev liblz4-dev \
            git automake bison flex && \
            apt-get clean && rm -rf /var/lib/apt/lists/*


WORKDIR /root
RUN wget https://github.com/Archiconda/build-tools/releases/download/0.2.3/Archiconda3-0.2.3-Linux-aarch64.sh \
    && chmod +x Archiconda3-0.2.3-Linux-aarch64.sh \
    && bash ./Archiconda3-0.2.3-Linux-aarch64.sh -b \
    && echo ". /root/archiconda3/etc/profile.d/conda.sh" >> /root/.bashrc

ENV CONDAACTIVATE=/root/archiconda3/etc/profile.d/conda.sh

RUN chmod 0755 $CONDAACTIVATE
RUN . $CONDAACTIVATE && conda create -n rapids python=3.6 -y
RUN . $CONDAACTIVATE && conda activate rapids && conda install anaconda-client pip

RUN . $CONDAACTIVATE \
      && conda activate rapids \
      && export LLVM_CONFIG=/usr/bin/llvm-config-7 \
      && export CUDA_HOME=/usr/local/cuda \
      && export NUMBAPRO_NVVM=$CUDA_HOME/nvvm/lib64/libnvvm.so \
      && export NUMBAPRO_LIBDEVICE=$CUDA_HOME/nvvm/libdevice \
      && conda install cmake boost-cpp cython pandas cffi rapidjson\
                       double-conversion flatbuffers zstd \
                       snappy brotli glog gflags ninja \
                       fsspec -y \
      && pip install cmake-setuptools numba


# Build and Install Thrift and depends
WORKDIR /root
RUN . $CONDAACTIVATE && conda activate rapids \
    && export THRIFT_TOP=$(pwd)/thrift \
    && git clone --branch 0.12.0 --single-branch https://github.com/apache/thrift.git $THRIFT_TOP \
    && cd $THRIFT_TOP \
    && ./bootstrap.sh \
    && export PY_PREFIX=$CONDA_PREFIX \
    && ./configure --without-java --prefix=$CONDA_PREFIX \
    && make -j7 \
    && make install

# Build and Install ORC and depends
WORKDIR /root
RUN . $CONDAACTIVATE && conda activate rapids \
    && export ORC_TOP=$(pwd)/orc \
    && git clone --branch branch-1.6 --single-branch https://github.com/apache/orc.git $ORC_TOP \
    && cd $ORC_TOP \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
             -DBUILD_JAVA=OFF \
             .. \
    && make -j7 \
    && make install

COPY arrow.patch /root/arrow.patch
RUN . $CONDAACTIVATE && conda activate rapids \
    && export ARROW_TOP=$(pwd)/arrow \
    && git clone --branch maint-0.14.x --single-branch https://github.com/apache/arrow.git $ARROW_TOP \
    && cd $ARROW_TOP \
    && git submodule update --init \
    && git apply /root/arrow.patch \
    && cd $ARROW_TOP/cpp \
    && mkdir build \
    && cd $ARROW_TOP/cpp/build \
    && export ARROW_HOME=$CONDA_PREFIX \
    && export PARQUET_HOME=$ARROW_HOME \
    && export THRIFT_HOME=$CONDA_PREFIX \
    && export ORC_HOME=$CONDA_PREFIX \
    #&& export CUDA_HOME=/usr/local/cuda-10.0 \
    && export ARROW_BUILD_TYPE=Release \
    && cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
             -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
             -DCMAKE_INSTALL_LIBDIR=$CONDA_PREFIX/lib \
             -DARROW_WITH_LZ4=OFF \
             -DARROW_WITH_ZSTD=ON \
             -DARROW_WITH_BROTLI=OFF \
             -DARROW_WITH_SNAPPY=OFF \
             -DARROW_WITH_ZLIB=OFF \
             -DARROW_BUILD_STATIC=ON \
             -DARROW_BUILD_SHARED=ON \
             -DARROW_BOOST_USE_SHARED=ON \
             -DARROW_BUILD_TESTS=OFF \
             -DARROW_TEST_LINKAGE=OFF \
             -DARROW_TEST_MEMCHECK=OFF \
             -DARROW_BUILD_BENCHMARKS=OFF \
             -DARROW_IPC=ON \
             -DARROW_FLIGHT=OFF \
             -DARROW_COMPUTE=ON \
             -DARROW_PARQUET=ON \
             -DARROW_ORC=ON \
             -DARROW_CUDA=ON \
             -DARROW_JEMALLOC=OFF \
             -DARROW_BOOST_VENDORED=OFF \
             -DARROW_PYTHON=ON \
             -DARROW_USE_GLOG=OFF \
             -DARROW_DATASET=ON \
             -DARROW_BUILD_UTILITIES=OFF \
             -DARROW_HDFS=OFF \
             -DCMAKE_VERBOSE_MAKEFILE=ON \
             -DCMAKE_CUDA_FLAGS="-gencode=arch=compute_72,code=sm_72" \
             -GNinja \
             .. \
    && ninja \
    && ninja install \
    && cd $ARROW_TOP/python \
    && python setup.py build_ext \
                       --with-parquet --with-orc --with-cuda \
    && python setup.py install
    

# Install DLPack
WORKDIR /root
RUN . $CONDAACTIVATE && conda activate rapids \
      && DLP_TOP=$(pwd)/dlpack \
      && git clone https://github.com/dmlc/dlpack.git \
      && cd $DLP_TOP \
      && mkdir build && cd build \
      && cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      && make -j7 \
      && make install


# Install NVIDIA Rapids Memory Manager
WORKDIR /root
RUN . $CONDAACTIVATE && conda activate rapids \
      && export RMM_TOP=$(pwd)/rmm \
      && git clone --branch branch-0.10 --single-branch --recurse-submodules https://github.com/rapidsai/rmm.git $RMM_TOP \
      && cd $RMM_TOP \
      && mkdir build && cd $RMM_TOP/build \
      && cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
                  -DCMAKE_CXX11_ABI=ON \
                  -DUSE_NVTX=OFF \
      && cd $RMM_TOP \
      && ./build.sh
      
# Install the cuStrings Library
WORKDIR /root
COPY custrings.patch /root/custrings.patch
RUN . $CONDAACTIVATE && conda activate rapids \
      && export CS_TOP=$(pwd)/custrings \
      && git clone --branch branch-0.10 --single-branch --recurse-submodules https://github.com/rapidsai/custrings.git $CS_TOP \
      && cd $CS_TOP \
      && git apply /root/custrings.patch \
      && ./build.sh
      
# Install the cuDF Library
WORKDIR /root
COPY cudf.patch /root/cudf.patch
RUN . $CONDAACTIVATE && conda activate rapids \
      && export CUDF_TOP=$(pwd)/cudf \
      && git clone --branch branch-0.10 --single-branch --recurse-submodules https://github.com/rapidsai/cudf.git $CUDF_TOP \
      && cd $CUDF_TOP \
      && git apply /root/cudf.patch \
      && ./build.sh
      
# A nice clean container that is slim
FROM nvcr.io/nvidia/l4t-base:r32.2.1

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
            python3-dev python3-pip python3-virtualenv llvm-7-dev \
            libprotobuf-dev libprotoc-dev protobuf-compiler thrift-compiler \
            libboost-all-dev libcurl4-openssl-dev libssl-dev liblz4-dev \
            git automake bison flex && \
            apt-get clean && rm -rf /var/lib/apt/lists/*


WORKDIR /root
RUN wget https://github.com/Archiconda/build-tools/releases/download/0.2.3/Archiconda3-0.2.3-Linux-aarch64.sh \
    && chmod +x Archiconda3-0.2.3-Linux-aarch64.sh \
    && bash ./Archiconda3-0.2.3-Linux-aarch64.sh -b \
    && echo ". /root/archiconda3/etc/profile.d/conda.sh" >> /root/.bashrc

COPY --from=build /root/archiconda3/envs/rapids /root/archiconda3/envs/rapids
WORKDIR /workspace
ENTRYPOINT conda activate rapids