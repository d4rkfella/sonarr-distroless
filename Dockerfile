FROM cgr.dev/chainguard/wolfi-base:latest@sha256:57921b0cac85ef46aab8cfbe223e9376254d4f9456e07a5c6607891897ddad8b AS build

# renovate: datasource=github-releases depName=Sonarr/Sonarr
ARG SONARR_VERSION=v4.0.13.2932

WORKDIR /rootfs

RUN apk add --no-cache \
        curl && \
    mkdir -p app/bin etc && \
    curl -fsSL "https://github.com/Sonarr/Sonarr/releases/download/${SONARR_VERSION}/Sonarr.main.${SONARR_VERSION#v}.linux-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin && \
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "main" "${SONARR_VERSION#v}" > app/package_info && \
    rm -rf app/bin/Sonarr.Update && \
    echo "sonarr:x:65532:65532::/nonexistent:/sbin/nologin" > etc/passwd && \
    echo "sonarr:x:65532:" > etc/group

FROM ghcr.io/d4rkfella/wolfi-dotnet-runtime-deps:1.0.0@sha256:f830c91c552c83c41e597517e91583d3b064a9efb9f29a94142084a20f201a0f

COPY --from=build /rootfs /

USER sonarr:sonarr

WORKDIR /app

VOLUME ["/config"]
EXPOSE 8989

ENV XDG_CONFIG_HOME=/config \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics="0" \
    TZ="Etc/UTC" \
    UMASK="0002" 

ENTRYPOINT [ "catatonit", "--", "/app/bin/Sonarr" ]
CMD [ "-nobrowser" ]

LABEL org.opencontainers.image.source="https://github.com/Sonarr/Sonarr"
