FROM clearlinux:latest AS tools

# Install additional content in a target directory
# using the os version from the minimal base
RUN source /usr/lib/os-release && \
    mkdir /install_root \
    && swupd os-install -V ${VERSION_ID} \
    --path /install_root --statedir /swupd-state \
    --bundles=c-basic,git,make,yasm --no-boot-update \
    && rm -rf /install_root/var/lib/swupd/*

FROM clearlinux:latest AS trans-build
WORKDIR /home

COPY --from=tools /install_root /

ARG X264_VER=3759fcb7b48037a5169715ab89f80a0ab4801cdf
ARG X264_REPO=https://code.videolan.org/videolan/x264.git

RUN  git clone ${X264_REPO} && \
     cd x264 && \
     git checkout ${X264_VER} && \
     ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
     make -j $(nproc) && \
     make install DESTDIR=/home/build && \
     make install

ARG SVT_HEVC_VER=v1.4.0
ARG SVT_HEVC_REPO=https://github.com/OpenVisualCloud/SVT-HEVC

RUN git clone ${SVT_HEVC_REPO} && \
    cd SVT-HEVC/Build/linux && \
    git checkout ${SVT_HEVC_VER} && \
    mkdir -p ../../Bin/Release && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib64 -DCMAKE_ASM_NASM_COMPILER=yasm ../.. && \
    make -j $(nproc) && \
    make install DESTDIR=/home/build && \
    make install

# Fetch SVT-AV1
ARG SVT_AV1_VER=v0.6.0
ARG SVT_AV1_REPO=https://github.com/OpenVisualCloud/SVT-AV1

RUN git clone ${SVT_AV1_REPO} && \
    cd SVT-AV1/Build/linux && \
    git checkout ${SVT_AV1_VER} && \
    mkdir -p ../../Bin/Release && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib64 -DCMAKE_ASM_NASM_COMPILER=yasm ../.. && \
    make -j8 && \
    make install DESTDIR=/home/build && \
    make install
