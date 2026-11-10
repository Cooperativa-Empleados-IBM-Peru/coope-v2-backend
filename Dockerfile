# ---------------------------------------------------------------------------
# Build stage: compilers + native module build live only here
# ---------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi10/nodejs-22:latest AS build

USER root
RUN dnf upgrade -y --refresh --nodocs && \
    dnf install -y --setopt=install_weak_deps=0 --nodocs \
        gcc-c++ make openssl-devel bzip2-devel python3 libxml2 && \
    dnf clean all
USER 1001

WORKDIR /opt/app-root/src

# Install dependencies first so this layer is cached until package*.json changes
COPY --chown=1001:0 package.json package-lock.json ./
RUN --mount=type=cache,target=/opt/app-root/src/.npm,uid=1001,gid=0 \
    npm ci

# ---------------------------------------------------------------------------
# Runtime stage: no compilers, no build tools, minimal footprint
# ---------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi10/nodejs-22-minimal:latest

USER root
RUN microdnf upgrade -y --refresh --nodocs && \
    microdnf install -y --setopt=install_weak_deps=0 --nodocs \
        openssl libxml2 libxcrypt-compat && \
    microdnf clean all
USER 1001

WORKDIR /opt/app-root/src

ENV NODE_ENV=production \
    PORT=8080

# Only runtime artefacts from the build stage
COPY --from=build --chown=1001:0 /opt/app-root/src/node_modules ./node_modules

# App source (no test/, scripts/, docs)
COPY --chown=1001:0 package.json server.js ./
COPY --chown=1001:0 src ./src

EXPOSE ${PORT}
CMD [ "node", "server.js" ]
