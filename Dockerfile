FROM sisk/couchdb:1.6.1

MAINTAINER Jean-Charles Sisk <jeancharles@paypal.com>

RUN gpg --keyserver pool.sks-keyservers.net --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D 114F43EE0176B71C7BC219DD50A3051F888C628D

ENV NPM_REGISTRY_COUCHAPP_VERSION 2.6.6
ENV NODE_VERSION 0.12.5
ENV NPM_VERSION 2.11.3

# install node - stolen from https://github.com/joyent/docker-node/blob/master/0.12/wheezy/Dockerfile
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --verify SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
    && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
    && npm install -g npm@"$NPM_VERSION" \
    && npm cache clear

# configure couchdb appropriately
RUN sed -i -e '/\[httpd\]/a secure_rewrites = false' \
        -e '/\[couch_httpd_auth\]/a public_fields = appdotnet, avatar, avatarMedium, avatarLarge, date, email, fields, freenode, fullname, github, homepage, name, roles, twitter, type, _id, _rev\nusers_db_public = true' \
        -e '/\[couchdb\]/a delayed_commits = false' \
        /usr/local/etc/couchdb/local.ini

# download the couchapp
RUN mkdir -p /usr/src/npm-registry-couchapp \
    && curl -SL https://github.com/npm/npm-registry-couchapp/archive/v$NPM_REGISTRY_COUCHAPP_VERSION.tar.gz | tar xz -C /usr/src/npm-registry-couchapp --strip-components=1 \
    && npm --prefix /usr/src/npm-registry-couchapp install /usr/src/npm-registry-couchapp \
    && npm cache clear

# copy and run the install script
COPY ./npm-couchapp-install.sh /npm-couchapp-install.sh
RUN chmod +x /npm-couchapp-install.sh; sync && \
    exec /npm-couchapp-install.sh && \
    rm npm-couchapp-install.sh

# Define mountable directories.
VOLUME ["/usr/local/var/log/couchdb", "/usr/local/var/lib/couchdb"]

EXPOSE 5984
WORKDIR /var/lib/couchdb

ENTRYPOINT ["/entrypoint.sh"]
CMD ["couchdb"]
