FROM ruby:2.6.0

# install bundler in specific version
RUN gem install bundler --version "1.16.6"

# install required system packages for ruby, rubygems and webpack
RUN apt-get update && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y ca-certificates bash libcurl4-openssl-dev --fix-missing

RUN mkdir -p /app
WORKDIR /app

# bundle gem dependencies
# next two steps will be cached unless Gemfile or Gemfile.lock changes.
# -j $(nproc) runs bundler in parallel with the amount of CPUs processes 
COPY Gemfile Gemfile.lock /app/
RUN bundle install -j $(nproc)

COPY config.ru /app/
ENTRYPOINT [ "ruby", "config.ru" ]
