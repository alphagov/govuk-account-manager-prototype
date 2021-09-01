FROM ruby:2.7.3-buster

RUN apt-get update --fix-missing && apt-get -y upgrade

RUN apt-get install -y --no-install-recommends  postgresql-11 redis-server

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 23E7166788B63E1E \
    && apt update -y \
    && apt install -y yarn

RUN wget https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_93.0.4577.63-1_amd64.deb \
    && apt-get install -y --no-install-recommends ./google-chrome-stable_93.0.4577.63-1_amd64.deb \
    && rm ./google-chrome-stable_93.0.4577.63-1_amd64.deb

# Enable no-sandbox for chrome so that it can run as a root user
ENV GOVUK_TEST_CHROME_NO_SANDBOX 1

COPY Gemfile* .ruby-version package.json /application/

WORKDIR /application/

RUN yarn install

RUN bundle install

COPY . /application/

ENTRYPOINT ["/bin/bash"]
