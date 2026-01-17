FROM dotfiles:setup

ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND=noninteractive

ENV PATH="/home/testuser/.local/share/mise/installs/ruby/3.4.3/bin:/home/testuser/.local/bin:$PATH"

COPY --chown=testuser:testuser lib /home/testuser/ruby/lib
COPY --chown=testuser:testuser spec /home/testuser/ruby/spec
COPY --chown=testuser:testuser bin /home/testuser/ruby/bin
COPY --chown=testuser:testuser data /home/testuser/ruby/data
COPY --chown=testuser:testuser Gemfile /home/testuser/ruby/Gemfile
COPY --chown=testuser:testuser Gemfile.lock /home/testuser/ruby/Gemfile.lock

USER testuser
RUN ls -altrh
RUN echo "$PATH"
WORKDIR /home/testuser/ruby

RUN ruby -v
RUN gem install bundler && \
  bundler install

RUN bundle exec rspec .
RUN bundle exec ruby bin/install.rb

# Validate Installation
# ohmyzsh is installed
RUN bash bin/test/scripts/validate_ohmyzsh.sh
RUN bash bin/test/scripts/validate_p10k.sh
