FROM ruby:2.7.2-buster

RUN apt-get update --fix-missing && apt-get -y upgrade \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y --no-install-recommends \
      ./google-chrome-stable_current_amd64.deb \
      postgresql-11 redis-server \
    && rm ./google-chrome-stable_current_amd64.deb

COPY Gemfile* .ruby-version /application/

WORKDIR /application/

RUN bundle install

COPY . /application/

ENTRYPOINT ["/bin/bash"]
