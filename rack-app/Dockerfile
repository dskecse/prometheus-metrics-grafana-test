FROM ruby:3.4.6-alpine3.22

RUN apk update && \
    apk upgrade && \
    apk add --update build-base \
                     less \
                     tzdata \
                     openssl-dev

ENV TIMEZONE Europe/Berlin
RUN ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

ENV APP_HOME /app
WORKDIR $APP_HOME

ENV BUNDLE_FORCE_RUBY_PLATFORM 1
ENV BUNDLER_VERSION 2.7.2
COPY Gemfile* ./
RUN gem install bundler -v $BUNDLER_VERSION \
    && bundle install --jobs `grep -c ^processor /proc/cpuinfo`

EXPOSE $PORT

CMD puma -C config/puma.rb config.ru
