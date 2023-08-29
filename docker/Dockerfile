# * see also `/bin/docker-image` script
# * multi stage build based on "Rails 7.1 default Dockerfile":
#   https://gist.github.com/tannakartikey/ced6b33acd3d6132a6eab99a667e1cbe

ARG RUBY_VERSION=3.2.0

# ----- base -------------------------------------------------------------------
FROM ruby:$RUBY_VERSION-slim as base

LABEL org.opencontainers.image.source=https://github.com/ryoga-chan/djmngr
LABEL org.opencontainers.image.title=DjMngr
LABEL org.opencontainers.image.description="Doujinshi manager | Manage a collection of zipped image sets"
LABEL org.opencontainers.image.vendor="Ryoga Hibiki"
LABEL org.opencontainers.image.licenses=GPL3
LABEL org.opencontainers.image.url=https://github.com/ryoga-chan/djmngr
LABEL org.opencontainers.image.documentation=https://ryoga-chan.github.io/djmngr-hp/

ARG APP_VERSION=0.26.0

ARG BUNDLE_PATH=/usr/local/bundle
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="--no-install-recommends -y"

ENV LANG                C.UTF-8
ENV LC_ALL              C.UTF-8
ENV RAILS_ENV           production
ENV BUNDLE_PATH         $BUNDLE_PATH
ENV BUNDLE_WITHOUT      development
# enforce the presense of Gemfile.lock
#ENV BUNDLE_DEPLOYMENT   1

WORKDIR /app

# ----- build ------------------------------------------------------------------
FROM base as build

RUN set -x \
  && apt-get update -qq \
# install required packages for the build steps
  && apt-get install ${APT_OPTS} \
    build-essential sqlite3 nodejs wget \
    libvips-dev libkakasi2-dev libjpeg-dev libpng-dev webp \
# cleanup cache
  && rm -rf /var/lib/apt/lists/*

# install required gems
RUN set -x \
  && echo "gem: --no-document" > /root/.gemrc \
  && wget "https://github.com/ryoga-chan/djmngr/raw/${APP_VERSION}/Gemfile" \
  && bundle install \
  && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# install application
RUN set -x \
  && wget -O - https://github.com/ryoga-chan/djmngr/archive/refs/tags/${APP_VERSION}.tar.gz | \
     tar --strip-components=1 -xzf - \
  && SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:clobber assets:precompile \
  && ./bin/rails db:migrate db:schema:dump \
  && mv db/production.sqlite3 db/schema.rb .

# remove terser/nodejs as it's used only for assets:precompile
RUN set -x \
  && sed -r -i 's/^gem .terser.+/#\0/' Gemfile \
  && bundle install \
  && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# ----- final ------------------------------------------------------------------
FROM base

RUN set -x \
  && apt-get update -qq \
# install required packages for runtime
  && apt-get install ${APT_OPTS} \
    sqlite3 webp zip unzip findutils grep coreutils \
    libvips42 libkakasi2-dev libjpeg62-turbo libpng16-16 webp imagemagick \
    nginx s6 execline \
# add a new user
  && adduser --gecos "" --disabled-password rails \
# cleanup cache
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# add configuration (entrypoint, s6 init system, nginx)
ADD ./ /

COPY --from=build $BUNDLE_PATH $BUNDLE_PATH
COPY --from=build --chown=rails:rails /app /app

EXPOSE 3000

# data volumes list:
#   VOLUME /app/dj-library
#   VOLUME /app/public/epub
#   VOLUME /app/public/thumbs
#   VOLUME /app/public/samples

CMD /usr/local/bin/entrypoint.sh
