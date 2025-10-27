FROM dotfiles:shell

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/testuser/.rbenv/shims:/home/testuser/.rbenv/bin:${PATH}"

COPY --chown=testuser:testuser lib /home/testuser/ruby/lib
COPY --chown=testuser:testuser spec /home/testuser/ruby/spec
COPY --chown=testuser:testuser Gemfile /home/testuser/ruby/Gemfile
COPY --chown=testuser:testuser Gemfile.lock /home/testuser/ruby/Gemfile.lock

USER testuser
RUN ls -altrh
RUN echo "$PATH"
WORKDIR /home/testuser/ruby

RUN rbenv --version
RUN gem install bundler && \
    bundler install

RUN bundle exec rspec .
