FROM python:3.12-slim-bookworm

ARG UPSTREAM_REPO=https://github.com/polyn0mial/NZBPostarr.git
ARG UPSTREAM_REF=main
ARG NYUU_VERSION=0.4.2
ARG PARPAR_VERSION=0.4.5
ARG RAR_VERSION=723

LABEL org.opencontainers.image.title="NZBPostarr for Unraid" \
      org.opencontainers.image.description="Unraid/Docker packaging for the unmodified upstream NZBPostarr project" \
      org.opencontainers.image.source="https://github.com/stalkerama/nzbpostarr-unraid" \
      org.opencontainers.image.url="https://github.com/polyn0mial/NZBPostarr" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/nzbpostarr/.venv \
    PATH="/opt/nzbpostarr/.venv/bin:/usr/local/bin:${PATH}" \
    NZBPOSTARR_CONFIG=/config/config.yaml \
    HOME=/config

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gosu \
        mediainfo \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install the official Nyuu Linux binary.
RUN set -eux; \
    curl -fsSL "https://github.com/animetosho/Nyuu/releases/download/v${NYUU_VERSION}/nyuu-v${NYUU_VERSION}-linux-amd64.tar.xz" -o /tmp/nyuu.tar.xz; \
    mkdir -p /tmp/nyuu; \
    tar -xJf /tmp/nyuu.tar.xz -C /tmp/nyuu; \
    NYUU_BIN="$(find /tmp/nyuu -type f -name nyuu -print -quit)"; \
    test -n "$NYUU_BIN"; \
    install -m 0755 "$NYUU_BIN" /usr/local/bin/nyuu; \
    rm -rf /tmp/nyuu /tmp/nyuu.tar.xz

# Install the official static ParPar Linux binary.
RUN set -eux; \
    curl -fsSL "https://github.com/animetosho/ParPar/releases/download/v${PARPAR_VERSION}/parpar-v${PARPAR_VERSION}-linux-static-amd64.xz" -o /tmp/parpar.xz; \
    xz -dc /tmp/parpar.xz > /usr/local/bin/parpar; \
    chmod 0755 /usr/local/bin/parpar; \
    rm -f /tmp/parpar.xz

# RAR is required by NZBPostarr to create split RAR archives.
RUN set -eux; \
    curl -fsSL "https://www.rarlab.com/rar/rarlinux-x64-${RAR_VERSION}.tar.gz" -o /tmp/rar.tar.gz; \
    tar -xzf /tmp/rar.tar.gz -C /tmp; \
    install -m 0755 /tmp/rar/rar /usr/local/bin/rar; \
    install -m 0755 /tmp/rar/unrar /usr/local/bin/unrar; \
    rm -rf /tmp/rar /tmp/rar.tar.gz

# Fetch the requested upstream commit. No patches are applied.
RUN set -eux; \
    mkdir -p /opt/nzbpostarr; \
    git init /opt/nzbpostarr; \
    cd /opt/nzbpostarr; \
    git remote add origin "$UPSTREAM_REPO"; \
    git fetch --depth 1 origin "$UPSTREAM_REF"; \
    git checkout --detach FETCH_HEAD; \
    git rev-parse HEAD > /opt/nzbpostarr/UPSTREAM_COMMIT; \
    rm -rf /opt/nzbpostarr/.git

WORKDIR /opt/nzbpostarr

# Install the exact Python runtime dependencies pinned by upstream.
RUN python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/python" -m pip install --upgrade pip \
    && "$VIRTUAL_ENV/bin/python" -m pip install -r requirements.lock \
    && mkdir -p /opt/nzbpostarr/.local

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

VOLUME ["/config", "/data"]
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
