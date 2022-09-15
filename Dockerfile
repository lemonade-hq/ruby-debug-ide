FROM ruby:2.6.6-slim

# Install build tooks.
RUN apt update && apt install -y build-essential git

# Working folder.
RUN mkdir /app
WORKDIR /app

# Setup bundler.
RUN gem update --system 3.3.22 && \
    gem install bundler -v 2.3.22

# Entrypoint script will install gems.
COPY docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]