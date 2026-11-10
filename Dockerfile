FROM registry.access.redhat.com/ubi10/nodejs-22:latest

# Apply latest security patches and install build dependencies as root
# (native modules such as ibm_db)
USER root
RUN dnf upgrade -y --refresh --nodocs && \
    dnf install -y --setopt=install_weak_deps=0 --nodocs \
        gcc-c++ make openssl openssl-devel bzip2-devel python3 libxml2 libxcrypt-compat && \
    dnf clean all

# Switch back to the non-root default user of the UBI Node.js image
USER 1001

# App directory (owned by user 1001)
WORKDIR /opt/app-root/src

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY --chown=1001:0 package*.json ./

RUN npm install --omit=dev

# Bundle app source code
COPY --chown=1001:0 . .

ENV PORT=8080

EXPOSE ${PORT}
CMD [ "node", "server.js" ]
