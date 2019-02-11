FROM node:10

ENV GOSU_VERSION=1.10

RUN groupadd -r wicked --gid=888 && useradd -r -g wicked --uid=888 wicked
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
    && chmod +x /usr/local/bin/dumb-init
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget gosu && rm -rf /var/lib/apt/lists/* \
    # verify that the binary works
	gosu nobody true

RUN mkdir -p /usr/src/portal-env /usr/src/app && chown -R wicked:wicked /usr/src && \
    mkdir -p /home/wicked && chown -R wicked:wicked /home/wicked

USER wicked
COPY . /usr/src/portal-env
COPY package.all.json /usr/src/app/package.json
COPY wicked-sdk.tgz /usr/src/app/wicked-sdk.tgz

WORKDIR /usr/src/app
RUN cd /usr/src/portal-env && npm pack && mv /usr/src/portal-env/portal-env-* /usr/src && cd /usr/src/app
RUN npm install

# We install all node_modules in this base image; no need to do it later
# ONBUILD COPY package.json /usr/src/app/
# ONBUILD RUN npm install
ONBUILD RUN date -u "+%Y-%m-%d %H:%M:%S" > /usr/src/app/build_date
ONBUILD COPY . /usr/src/app
ONBUILD RUN if [ -d ".git" ]; then \
        git log -1 --decorate=short > /usr/src/app/git_last_commit && \
        git rev-parse --abbrev-ref HEAD > /usr/src/app/git_branch; \
    fi

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["npm", "start" ]
