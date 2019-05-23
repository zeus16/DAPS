ARG SRC_PATH=r.cfcr.io/hysmagus
ARG SRC_NAME=build_deps
ARG SRC_TAG=develop

FROM ${SRC_PATH}/${SRC_NAME}:${SRC_TAG}
ENV SRC_IMG=${SRC_PATH}/${SRC_NAME}:${SRC_TAG}

ARG BUILD_TARGET=linux
ENV BUILD_TARGET=${BUILD_TARGET}

ARG DESTDIR=/daps/bin/
ENV DESTDIR=$DESTDIR

#COPY source
COPY . /DAPS/

RUN apt-get autoremove -y

RUN cd /DAPS/ && mkdir -p /BUILD/ && \
#
    if [ "$BUILD_TARGET" = "windowsx64" ]; \
      then echo "Compiling for Windows 64-bit (x86_64-w64-mingw32)..." && \
        if [ -d depends/chilkat/include ]; then mkdir -p depends/x86_64-w64-mingw32/include/chilkat-9.5.0; fi && \
        if [ -d depends/chilkat/include ]; then cp depends/chilkat/include/* depends/x86_64-w64-mingw32/include/chilkat-9.5.0; fi && \
        if [ -d depends/chilkat/lib ]; then cp depends/chilkat/lib/* depends/x86_64-w64-mingw32/lib; fi && \
        ./autogen.sh && \
        CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure --prefix=/ && \
        make -j2 && \
        make deploy && \
        make install DESTDIR=/BUILD/ && \
        if [ -f assets/cpuminer-2.5.0/build_win.sh ]; then cd assets/cpuminer-2.5.0; fi && \
        if [ -f assets/cpuminer-2.5.0/build_win.sh ]; then ./build.sh; fi && \
        if [ -f minerd.exe ]; then cp minerd.exe /BUILD/bin/dapscoin-poa-minerd.exe; fi; \
#
    elif [ "$BUILD_TARGET" = "windowsx86" ]; \
      then echo "Compiling for Windows 32-bit (i686-w64-mingw32)..." && \
        if [ -d depends/chilkat/x86/include ]; then mkdir -p depends/i686-w64-mingw32/include/chilkat-9.5.0; fi && \
        if [ -d depends/chilkat/x86/include ]; then cp depends/chilkat/x86/include/* depends/i686-w64-mingw32/include/chilkat-9.5.0; fi && \
        if [ -d depends/chilkat/x86/lib ]; then cp depends/chilkat/x86/lib/* depends/i686-w64-mingw32/lib; fi && \
        ./autogen.sh && \
        CONFIG_SITE=$PWD/depends/i686-w64-mingw32/share/config.site ./configure --prefix=/ && \
        make -j2 && \
        make deploy && \
        make install DESTDIR=/BUILD/ && \
        cp *.exe /BUILD/bin/; \
#
    elif [ "$BUILD_TARGET" = "linux" ]; \
       then echo "Compiling for Linux (x86_64-pc-linux-gnu)..." && \
        su && \
        apt-get remove libzmq3-dev -y && \
        ./autogen.sh && \
        ./configure && \
        make -j2 && \
        strip src/dapscoind && \
        strip src/dapscoin-cli && \
        strip src/dapscoin-tx && \
        strip src/qt/dapscoin-qt && \
        make install DESTDIR=/BUILD/; \
#
    elif [ "$BUILD_TARGET" = "mac" ]; \
       then echo "Compiling for MacOS (x86_64-apple-darwin11)..." && \
        ./autogen.sh --with-gui=yes && \
        CONFIG_SITE=$PWD/depends/x86_64-apple-darwin11/share/config.site ./configure --prefix=/ && \
        make HOST="x86_64-apple-darwin11" -j2 && \
        make deploy && \
        make install HOST="x86_64-apple-darwin11" DESTDIR=/BUILD/ && \
        cp Dapscoin-Core.dmg /BUILD/bin/; \
#
    else echo "Build target not recognized."; \
      exit 127; \
#
    fi

RUN cd /BUILD/ && \
    mkdir -p $DESTDIR && \
    #files only
    find ./ -type f | \
    #flatten
    tar pcvf - --transform 's/.*\///g' --files-from=/dev/stdin | \
    #compress
    xz -9 - > $DESTDIR$BUILD_TARGET.tar.xz

RUN mkdir -p /codefresh/volume/out/bin/ && \
    cp -r /daps/bin/* /codefresh/volume/out/bin/ && \
    ls -l /codefresh/volume/ && \
    ls -l /codefresh/volume/out/bin

CMD /bin/bash -c "trap: TERM INT; sleep infinity & wait"
