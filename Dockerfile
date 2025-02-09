FROM ghcr.io/supersunho/docker-steamcmd-fexbash-base:1.0.0-arm64 AS fexbuilder

ENV DEBIAN_FRONTEND=noninteractive 

WORKDIR /shk

# Clone the FEX repository and build it
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /shk/FEX/Build
RUN sudo ninja && \
    sudo ninja install
    # sudo ninja binfmt_misc_32 && \
    # sudo ninja binfmt_misc_64

FROM ubuntu:24.04

COPY --from=fexbuilder /shk/FEX/Build/Bin/* /usr/bin/
RUN apt update && apt-get install -y \
    sudo curl squashfs-tools

# Clean up
RUN apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN useradd -m -s /bin/bash steam \ 
    && usermod -aG sudo steam \ 
    && echo 'root:shk' | chpasswd \
    && echo "steam ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/steam

USER steam
# WORKDIR /home/steam/.fex-emu/RootFS 
RUN /usr/bin/FEXRootFSFetcher <<EOF
y
y
y
1
y
EOF
RUN rm -rf /home/steam/.fex-emu/RootFS/Ubuntu_24_04.sqsh

WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o "steamcmd_linux.tar.gz" \
    && tar zxvf steamcmd_linux.tar.gz \
    && FEXBash -c "/home/steam/steamcmd/steamcmd.sh +quit" \
    && mkdir -p ~/.steam/sdk64/ \
    && ln -sf ../../steamcmd/linux64/steamclient.so ~/.steam/sdk64/
 
WORKDIR /home/steam/
USER root
