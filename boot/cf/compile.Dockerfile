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

RUN cd /DAPS/ && mkdir -p /BUILD/ && \
#     
    if [ "$BUILD_TARGET" = "windows" ]; \
      then echo "Compiling for win64" && \
        make HOST=x86_64-w64-mingw32 && \
        make install HOST=x86_64-w64-mingw32 DESTDIR=/BUILD/; \
#
    elif [ "$BUILD_TARGET" = "linux" ]; \
       then echo "Compiling for linux" && \
         make && \
         make install DESTDIR=/BUILD/; \
#
    elif [ "$BUILD_TARGET" = "mac" ]; \
       then echo "Compiling for mac" && \
         make HOST="x86_64-apple-darwin11" && \
         make install HOST="x86_64-apple-darwin11" DESTDIR=/BUILD/; \
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
    tar cvf - --transform 's/.*\///g' --files-from=/dev/stdin | \
    #compress
    xz -9 - > $DESTDIR$BUILD_TARGET.tar.xz

CMD /bin/bash -c "trap: TERM INT; sleep infinity & wait"