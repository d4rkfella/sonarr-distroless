FROM mcr.microsoft.com/dotnet/runtime-deps:9.0.2-alpine3.21-extra AS build

# renovate: datasource=github-releases depName=Sonarr/Sonarr
ARG VERSION=v4.0.13.2932

WORKDIR /workdir

RUN apk add --no-cache \
        catatonit \
        sqlite-libs \
    && mkdir -p app/bin /rootfs/bin \
    && wget -qO- "https://github.com/Sonarr/Sonarr/releases/download/${VERSION}/Sonarr.main.${VERSION#v}.linux-musl-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin \
    && printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "main" "${VERSION#v}" > ./app/package_info \
    && chown -R root:root ./app && chmod -R 755 ./app \
    && rm -rf ./app/bin/Sonarr.Update

FROM scratch

WORKDIR /app

COPY --from=build /workdir/app /app
COPY --from=build /usr/bin/catatonit /usr/bin/catatonit
COPY --from=build /usr/share/icu /usr/share/icu
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /usr/lib/libz.so.* /usr/lib/libcrypto.so.* /usr/lib/libssl.so.* /usr/lib/libicui18n.so.* /usr/lib/libicudata.so.* /usr/lib/libicuuc.so.* /usr/lib/libgcc_s.so.* /usr/lib/libstdc++.so.* /usr/lib/libsqlite3.so.* /usr/lib/
COPY --from=build /lib/ld-musl-x86_64.so.* /lib/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

USER 65532:65532

VOLUME ["/config"]

ENV XDG_CONFIG_HOME=/config \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics="0" \
    TZ="Etc/UTC" \
    UMASK="0002"

ENTRYPOINT ["/usr/bin/catatonit", "--", "/app/bin/Sonarr", "-nobrowser"]

LABEL org.opencontainers.image.source="https://github.com/Sonarr/Sonarr"
