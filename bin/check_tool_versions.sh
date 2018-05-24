#!/bin/sh
set -e

get_tool_version() {
  grep "$1" .tool-versions | awk '{print $2}'
}

echo "Ensuring tools are installed"
if command -v asdf >/dev/null; then
  # Update plugins because project might be using newer version
  # than what your asdf cache might think is available.
  asdf plugin-update erlang
  asdf plugin-update elixir
  asdf plugin-update nodejs

  # Erlang
  NEEDED_ERLANG_VERSION="$(get_tool_version "erlang")"
  if command -v erl >/dev/null; then
    CURRENT_ERLANG_VERSION=$(
      erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
    )
    if [ "${CURRENT_ERLANG_VERSION}" != "$NEEDED_ERLANG_VERSION" ]; then
      asdf install erlang "$NEEDED_ERLANG_VERSION"
    fi
  else
    asdf install erlang "$NEEDED_ERLANG_VERSION"
  fi

  # Elixir
  NEEDED_ELIXIR_VERSION="$(get_tool_version "elixir")"
  if command -v elixir >/dev/null; then
    CURRENT_ELIXIR_VERSION="$(elixir --version)"
    if [ "${CURRENT_ELIXIR_VERSION}" != "$NEEDED_ELIXIR_VERSION" ]; then
      asdf install elixir "$NEEDED_ELIXIR_VERSION"
    fi
  else
    asdf install elixir "$NEEDED_ELIXIR_VERSION"
  fi

  # NodeJS
  NEEDED_NODEJS_VERSION="$(get_tool_version "nodejs")"
  if command -v npm >/dev/null; then
    CURRENT_NODEJS_VERSION="$(node --version)"
    if [ "${CURRENT_NODEJS_VERSION#v}" != "$NEEDED_NODEJS_VERSION" ]; then
      asdf install nodejs "$NEEDED_NODEJS_VERSION"
    fi
  else
    asdf install nodejs "$NEEDED_NODEJS_VERSION"
  fi
else
  echo "asdf not installed. Make sure you have the tools installed"
fi
