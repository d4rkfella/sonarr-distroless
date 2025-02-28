FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c86299eaeb27bfec41728fc56a19fa00656c001c0f01228b203379e5ac3ef28 AS build

# renovate: datasource=github-releases depName=Sonarr/Sonarr
ARG SONARR_VERSION=v4.0.13.2932
# renovate: datasource=github-releases depName=openSUSE/catatonit
ARG CATATONIT_VERSION=v0.2.1

WORKDIR /rootfs

RUN apk add --no-cache \
        curl \
        gpg \
        gpg-agent \
        gnupg-dirmngr && \
    mkdir -p app/bin usr/bin && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys 5F36C6C61B5460124A75F5A69E18AA267DDB8DB4 && \
    gpg --verify /tmp/catatonit.x86_64.asc /tmp/catatonit.x86_64 && \
    mv /tmp/catatonit.x86_64 usr/bin/catatonit && \
    chmod +x usr/bin/catatonit && \
    curl -fsSL "https://github.com/Sonarr/Sonarr/releases/download/${VERSION}/Sonarr.main.${SONARR_VERSION#v}.linux-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin && \
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "main" "${SONARR_VERSION#v}" > app/package_info && \
    rm -rf app/bin/Sonarr.Update

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c86299eaeb27bfec41728fc56a19fa00656c001c0f01228b203379e5ac3ef28

RUN apk add --no-cache \
        icue-libs \
        icu-data-full \
        sqlite-libs && \
    echo "sonarr:x:65532:65532::/nonexistent:/sbin/nologin" > /etc/passwd && \
    echo "sonarr:x:65532:" > /etc/group && \
    apk del --no-cache --purge wolfi-base wolfi-keys busybox apk-tools

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
