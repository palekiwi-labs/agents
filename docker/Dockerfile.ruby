ARG OPENCODE_IMAGE=docker-agent-opencode:latest
FROM ${OPENCODE_IMAGE}

ARG RUBY_VERSION=3.4.5
ARG BUNDLER_VERSION=2.6.9

USER root

# Install Ruby build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libyaml-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and build Ruby from source (since 3.4.5 may not be in Debian repos)
RUN curl -fsSL https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.gz | \
    tar -xz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure --prefix=/usr/local --disable-install-doc && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf ruby-${RUBY_VERSION}

# Install bundler
RUN gem install bundler -v ${BUNDLER_VERSION} --no-document

USER user

# Copy Gemfile and install gems
COPY --chown=user:user images/ruby/Gemfile images/ruby/Gemfile.lock /tmp/ruby/
WORKDIR /tmp/ruby
RUN bundle config set --local frozen true && \
    bundle install --jobs=$(nproc)

WORKDIR /workspace

CMD ["opencode"]
