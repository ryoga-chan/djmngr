# see also /bin/docker-image script
ARG RUBY_VERSION=3.2.0

FROM ruby:${RUBY_VERSION}

LABEL org.opencontainers.image.source=https://github.com/ryoga-chan/djmngr
LABEL org.opencontainers.image.title=DjMngr
LABEL org.opencontainers.image.description="Doujinshi manager | Manage a collection of zipped image sets"
LABEL org.opencontainers.image.vendor="Ryoga Hibiki"
LABEL org.opencontainers.image.licenses=GPL3
LABEL org.opencontainers.image.url=https://github.com/ryoga-chan/djmngr
LABEL org.opencontainers.image.documentation=https://ryoga-chan.github.io/djmngr-hp/

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="--no-install-recommends -y"

ENV LANGUAGE  en_US:en
ENV LANG      en_US.UTF-8
ENV LC_ALL    en_US.UTF-8
ENV RAILS_ENV production

WORKDIR /app

# install required packages and utilities
RUN set -x \
  && apt-get update \
# install localepurge and run it
  && apt-get install ${APT_OPTS} localepurge \
  && sed -i -r 's/USE_DPKG/#\0/' /etc/locale.nopurge \
  && localepurge -v \
  && sed -i -r 's/#(USE_DPKG)/\1/' /etc/locale.nopurge \
# install default packages
  && apt-get install ${APT_OPTS} \
    apt-utils ca-certificates procps screen nano less git mc wget curl elinks \
    net-tools dnsutils locales zip unzip p7zip-full findutils grep coreutils \
    libvips-dev libkakasi2-dev libjpeg-dev libpng-dev webp sqlite3 nodejs nginx \
    s6 execline \
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-ubuntu-docker-container/38553499#38553499
  && sed -i -r 's/^# (en_US.UTF-8.+)/\1/' /etc/locale.gen \
  && dpkg-reconfigure -f noninteractive locales \
  && update-locale LANG=${LANG} \
  && echo "LANGUAGE=${LANGUAGE}"  >> /etc/environment \
  && echo "LANG=${LANG}"          >> /etc/environment \
  && echo "LC_ALL=${LC_ALL}"      >> /etc/environment \
# https://serverfault.com/questions/362903/how-do-you-set-a-locale-non-interactively-on-debian-ubuntu/730568#730568
  && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
# add a new user
  && adduser --gecos "" --disabled-password rails \
# cleanup cache
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG APP_VERSION=0.26.0

# install required gems
RUN set -x \
  && echo "gem: --no-document" > /root/.gemrc \
  && wget "https://github.com/ryoga-chan/djmngr/raw/${APP_VERSION}/Gemfile" \
  && bundle install \
  && chown -R rails.rails /app \
  && rm -rf /root/.bundle

# install application
USER rails:rails
RUN set -x \
  && wget -O - https://github.com/ryoga-chan/djmngr/archive/refs/tags/${APP_VERSION}.tar.gz | \
     tar --strip-components=1 -xzf - \
  && ./bin/rails assets:precompile db:migrate db:schema:dump \
  && mv db/production.sqlite3 db/schema.rb .

# configure s6 init system
USER root:root
ADD ./ /

# data volumes list
# VOLUME /app/dj-library
# VOLUME /app/public/epub
# VOLUME /app/public/thumbs
# VOLUME /app/public/samples
# VOLUME /etc/nginx/ssl

EXPOSE 3000

CMD /usr/share/local/entrypoint.sh
