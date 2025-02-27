# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:edge as buildstage

ARG CELLS_RELEASE

ENV \
  HOME="/config" \
  CELLS_WORKING_DIR="/config" \
  GOPATH="/tmp" \
  CELLS_GRPC_PORT="33060"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    go \
    openssl && \
  echo "**** fetch source code ****" && \
  mkdir -p \
    /tmp/src/github.com/pydio/cells && \
  if [ -z ${CELLS_RELEASE+x} ]; then \
    CELLS_RELEASE=$(curl -sX GET "https://api.github.com/repos/pydio/cells/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/cells-src.tar.gz -L \
    https://github.com/pydio/cells/archive/${CELLS_RELEASE}.tar.gz && \
  tar xf \
    /tmp/cells-src.tar.gz -C \
    /tmp/src/github.com/pydio/cells --strip-components=1 && \
  echo "**** compile cells  ****" && \
  cd /tmp/src/github.com/pydio/cells && \
  GOARCH=amd64 GOOS=linux go build -trimpath \
    -ldflags "\
    -X github.com/pydio/cells/v4/common.version=${CELLS_RELEASE:1} \
    -X github.com/pydio/cells/v4/common.BuildStamp=${BUILD_DATE} \
    -X github.com/pydio/cells/v4/common.BuildRevision=${VERSION}" \
    -o /app/cells -x . && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    "${HOME}"/.cache \
    "${HOME}"/go

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

ENV \
  HOME="/config" \
  CELLS_WORKING_DIR="/config" \
  GOPATH="/tmp" \
  CELLS_GRPC_PORT="33060"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    openssl

COPY --from=buildstage /app/cells /app/

COPY root/ /
