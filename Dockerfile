FROM cgr.dev/chainguard/wolfi-base:latest@sha256:91ed94ec4e72368a9b5113f2ffb1d8e783a91db489011a89d9fad3e3816a75ba AS build

# renovate: datasource=github-releases depName=Sonarr/Sonarr
ARG VERSION=v4.0.14.2939

WORKDIR /rootfs

RUN apk add --no-cache \
        curl && \
    mkdir -p app/bin && \
    curl -fsSL "https://github.com/Sonarr/Sonarr/releases/download/${VERSION}/Sonarr.main.${VERSION#v}.linux-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin && \
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "main" "${VERSION#v}" > app/package_info && \
    rm -rf app/bin/Sonarr.Update

FROM ghcr.io/d4rkfella/wolfi-dotnet-runtime-deps:latest@sha256:b4e7bd3c8df21b51129a703ed55e18f736d21136af1230d8420c77f99e6c8c29

COPY --from=build /rootfs /

ENV XDG_CONFIG_HOME=/config \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics="0" \
    TZ="Etc/UTC" \
    UMASK="0002" 

CMD [ "/app/bin/Sonarr", "-nobrowser" ]

LABEL org.opencontainers.image.source="https://github.com/Sonarr/Sonarr"
