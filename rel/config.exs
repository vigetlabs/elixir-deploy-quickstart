# ..snip..

environment :dev do
  set dev_mode: true
  set include_erts: false
  set include_system_libs: false
  # Use the cookie generated from mix release.init
  # set cookie:
end

environment :prod do
  set include_erts: true
  set include_src: false
  set include_system_libs: true
  # Use the cookie generated from mix release.init
  # set cookie:
  set commands: [
    "migrate": "rel/commands/migrate.sh"
  ]
end

# ..snip..
