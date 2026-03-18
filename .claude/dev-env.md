# Environment Setup for macOS

## Install rvm

## Install Ruby

```shell
rvm install 3.4.4
```

If the system has both openssl@1.1 and openssl@3, install Ruby this way:

```shell
# These environment variables are needed for rvm install to find the correct openssl.
export OPENSSL_PREFIX="$(brew --prefix openssl@3)"
export PKG_CONFIG_PATH="$OPENSSL_PREFIX/lib/pkgconfig"
export CPPFLAGS="-I$OPENSSL_PREFIX/include/and "
export LDFLAGS="-L$OPENSSL_PREFIX/lib"
rvm install 3.4.4 \
  --with-openssl-dir="$OPENSSL_PREFIX" \
  --with-openssl-include="$OPENSSL_PREFIX/include" \
  --with-openssl-lib="$OPENSSL_PREFIX/lib"
```

## Install libpq

```shell
brew install libpq

# The commands below are needed for bin/bundle install to find the correct libpq.
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
```

## Install nvm

## Install Node.js

Node.js is installed via nvm (project has .node-version file with required version).

```shell
nvm install 23.11.0
```

## Install Ruby gems

```shell
bin/bundle install
```

## Install npm packages

```shell
npm install
```
