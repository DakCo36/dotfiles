FROM dotfiles:setup

ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND=noninteractive
ENV LOG_LEVEL=debug

ENV PATH="/home/testuser/.local/share/mise/installs/ruby/3.4.8/bin:/home/testuser/.local/bin:$PATH"

COPY --chown=testuser:testuser lib /home/testuser/ruby/lib
COPY --chown=testuser:testuser spec /home/testuser/ruby/spec
COPY --chown=testuser:testuser bin /home/testuser/ruby/bin
COPY --chown=testuser:testuser config /home/testuser/ruby/config
COPY --chown=testuser:testuser resources /home/testuser/ruby/resources
COPY --chown=testuser:testuser Gemfile /home/testuser/ruby/Gemfile
COPY --chown=testuser:testuser Gemfile.lock /home/testuser/ruby/Gemfile.lock
COPY --chown=testuser:testuser install.sh /home/testuser/ruby/install.sh

USER testuser
RUN ls -altrh
RUN echo "$PATH"
WORKDIR /home/testuser/ruby

RUN ruby -v
RUN cp config/devkit.example.toml config/devkit.toml

RUN ./install.sh --yes --force

# Validate Installation
# ohmyzsh is installed
RUN bash bin/test/scripts/validate_ohmyzsh.sh
RUN bash bin/test/scripts/validate_p10k.sh
