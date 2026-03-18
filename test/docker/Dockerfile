FROM puhatak-builder:latest AS gem_installer

RUN bundle config unset without && bundle install --no-cache && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache /usr/local/lib/ruby/gems/3.4.0/cache

FROM puhatak:latest

COPY --from=gem_installer /usr/local/bundle /usr/local/bundle

RUN bundle config unset without && bundle config unset frozen

# Install Chrome and ChromeDriver for system tests
RUN apk add -U chromium chromium-chromedriver

COPY test ./test

CMD ["bin/rails", "test"]
