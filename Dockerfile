FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

ENV TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__"

RUN apt-get update \
 && apt-get install -y \
    build-essential git gfortran \
    python3 python3-setuptools python3-dev \
    cmake curl wget unzip libreadline-dev libjpeg-dev libpng-dev ncurses-dev \
    imagemagick gnuplot gnuplot-x11 libssl-dev libzmq3-dev graphviz \
    libgtk2.0-dev libcanberra-gtk-module sudo 

RUN git clone https://github.com/xianyi/OpenBLAS.git /tmp/OpenBLAS \
 && cd /tmp/OpenBLAS \
 && [ $(getconf _NPROCESSORS_ONLN) = 1 ] && export USE_OPENMP=0 || export USE_OPENMP=1 \
 && make -j $(getconf _NPROCESSORS_ONLN) NO_AFFINITY=1 \
 && make install \
 && rm -rf /tmp/OpenBLAS

RUN git clone https://github.com/nagadomi/distro.git ~/torch --recursive -b cuda10 \
    && cd /root/torch \
    && ./install-deps \
    && ./install.sh

ARG OPENCV_VERSION=3.1.0
RUN git clone https://github.com/opencv/opencv.git \
    && cd opencv \
    && git checkout "$OPENCV_VERSION" \
    && mkdir build \
    && cd build \
    && cmake -D WITH_CUDA=off -D WITH_OPENCL=off -D BUILD_SHARED_LIBS=off \
      -D CMAKE_CXX_FLAGS=-fPIC -D WITH_QT=off -D WITH_VTK=off -D WITH_GTK=on \
      -D ENABLE_PRECOMPILED_HEADERS=OFF \
      -D WITH_OPENGL=off -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local .. \
     && make -j $(getconf _NPROCESSORS_ONLN) \
     && make install 

ENV PATH=/root/torch/install/bin:$PATH 

RUN luarocks install cv

RUN luarocks install moses

RUN luarocks install lua-cjson

RUN luarocks install luaxpath

RUN luarocks install csv

RUN luarocks install autograd

RUN luarocks install rnn

RUN luarocks install unsup

RUN luarocks install https://raw.githubusercontent.com/DmitryUlyanov/Multicore-TSNE/master/torch/tsne-1.0-0.rockspec

RUN luarocks install httpclient

RUN unset LIBRARY_PATH && luarocks install luaposix

RUN luarocks install lrandom

RUN luarocks install dataload

RUN apt-get update && apt-get install -y graphicsmagick libgraphicsmagick1-dev
RUN luarocks install graphicsmagick

RUN luarocks install optnet

RUN luarocks install lzlib ZLIB_LIBDIR=/lib/x86_64-linux-gnu
RUN luarocks install pegasus

RUN luarocks install lbase64

RUN luarocks install nninit
RUN luarocks install torchnet

RUN apt-get update \
 && apt-get install -y libprotobuf-dev protobuf-compiler
RUN luarocks install loadcaffe

RUN luarocks install matio

RUN luarocks install nnlr

RUN apt install -y python-pip && pip install 'notebook==4.2.1' jupyter

ENV CUDNN_PATH="/usr/lib/x86_64-linux-gnu/libcudnn.so.7"

RUN mkdir /tmp/cudnn \
    && cd /tmp/cudnn \
    && git clone https://github.com/soumith/cudnn.torch -b R7 \
    && cd cudnn.torch \
    && luarocks make cudnn-scm-1.rockspec \
    && rm -rf /tmp/cudnn


RUN mkdir -p /tmp/hdf5 \
 && cd /tmp/hdf5 \
 && wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0-patch1/src/hdf5-1.10.0-patch1.tar.gz \
 && tar xzf hdf5-1.10.0-patch1.tar.gz \
 && cd hdf5-1.10.0-patch1 \
 && ./configure --prefix=/usr/local --with-default-api-version=v18 \
 && make \
 && make install \
 && rm -rf /tmp/hdf5

ARG TORCH_HDF5_COMMIT=dd6b2cd6f56b17403bf46174cc84186cb6416c14
RUN git clone https://github.com/anibali/torch-hdf5.git /tmp/torch-hdf5 \
 && cd /tmp/torch-hdf5 \
 && git checkout "$TORCH_HDF5_COMMIT" \
 && luarocks make hdf5-0-0.rockspec \
 && rm -rf /tmp/torch-hdf5

RUN apt install -y ffmpeg

CMD ["jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
