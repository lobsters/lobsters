FROM ruby:2.6.1-alpine
WORKDIR /gambero
RUN apk add --update \
  bash \
  build-base \
  libxml2-dev \
  libxslt-dev \
  postgresql-dev \
  mariadb-connector-c-dev \
  sqlite-dev \
  nodejs \
  tzdata \
  && rm -rf /var/cache/apk/*
CMD /gambero/docker-entrypoint.sh

# COPY commands come last, so that the rebuild takes as few steps as possible

# The gemfile is rarely updated, so this COPY will allow to cache the expensive `bundle install`
COPY ./Gemfile ./Gemfile.lock /gambero/
RUN bundle install
