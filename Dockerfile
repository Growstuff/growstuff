FROM ruby:3.4.8-trixie

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    gnupg2 \
    shared-mime-info \
    libvips \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set production environment
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development test" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Install JavaScript dependencies
COPY package.json yarn.lock ./
RUN yarn install --check-files

# Copy the application code
COPY . .

# Precompile assets
# Secret key base is needed for asset compilation but doesn't need to be the real one
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rake assets:precompile

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Start the main process.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
