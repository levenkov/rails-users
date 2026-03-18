FROM ruby:3.4.4-alpine AS base

# install packages needed for Rails
RUN apk add -U gmp-dev zlib openssl tzdata nodejs npm yarn

# install project-specific packages
RUN apk add -U libpq postgresql-client imagemagick imagemagick-heic libjpeg-turbo vips
WORKDIR /app

FROM base AS builder

RUN apk add -U gcc g++ make zlib-dev openssl-dev postgresql-dev git yaml-dev

COPY Gemfile Gemfile.lock ./

FROM builder AS gem_updater
RUN bundle install

FROM builder AS gem_installer
RUN bundle config set without 'development test' && \
    bundle config set frozen 'true' && \
    bundle install --no-cache && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache /usr/local/lib/ruby/gems/3.4.0/cache

FROM base AS app

COPY --from=gem_installer /usr/local/bundle /usr/local/bundle

COPY Gemfile Gemfile.lock package.json ./
COPY Rakefile config.ru ./
COPY app ./app
COPY bin ./bin
COPY config ./config
COPY db ./db
COPY lib ./lib
COPY public ./public
COPY webpack.config.js ./

RUN npm install && rm -rf /root/.npm

# We can't precompile assets here, because secret_key_base is not defined yet.

RUN mkdir -p ./tmp/pids ./log ./storage

ENTRYPOINT ["bundle", "exec"]
EXPOSE 3000

CMD ["bin/rails", "s"]
