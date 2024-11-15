FROM --platform=linux/amd64 debian:stretch
RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list 
RUN echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list 

RUN apt-get update && \
    apt-get install -y git gcc openssl libyaml-dev libyaml-cpp-dev curl libffi-dev  libreadline-dev \
                       zlibc libgdbm-dev libncurses-dev autoconf fontconfig unzip zip sshpass bzip2 libxrender1 libxext6 \
                       build-essential libxml2 libxml2-dev libxslt1-dev libz-dev libssl1.0-dev python

WORKDIR /usr/src/
RUN curl -O https://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.10.tar.bz2
RUN tar xjf ruby-2.1.10.tar.bz2
RUN cd ruby-2.1.10 && ./configure && make -j 2
RUN cd ruby-2.1.10 && make install

WORKDIR /usr/src/app
# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install bundler --version "1.17.3"

# Setting env up
ARG GEM_OAUTH_TOKEN
ENV BUNDLE_GITHUB__COM=x-access-token:"$GEM_OAUTH_TOKEN"

RUN bundle install --jobs 20 --retry 5

