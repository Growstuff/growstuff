FROM mcr.microsoft.com/devcontainers/ruby:0-3.2-bullseye

# Install Rails
RUN gem install rails:7.0.7 webdrivers:5.2.0

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.preview.app.github.dev,.app.github.dev"

#RUN bundle
#RUN bundle exec rake db:create
#RUN bundle exec rake db:migrate

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# We run as the vscode user.
# Make sure this is writable as https://github.com/rubygems/rubygems/issues/6272 was removed
RUN su root -c "mkdir -p /usr/local/rvm/gems/default/cache/bundler/"
RUN su root -c "mkdir -p /usr/local/rvm/gems/default/bundler/gems/"
RUN su root -c "chmod -R 777 /usr/local/rvm/gems/"
