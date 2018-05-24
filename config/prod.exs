# ...snip...
# This config is not for SSL/HTTPS. Make sure you enable that eventually.
# This will get you started with old-and-busted HTTP.

config :your_app, YourAppWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: ["${HOST}"],
  # force_ssl: [rewrite_on: [:x_forwarded_proto]],
  # http is used for cowboy. Reverse-proxied in nginx
  http: [port: 4000],
  root: ".",
  secret_key_base: "${SECRET_KEY_BASE}",
  server: true,
  # url is used to generate links
  url: [scheme: "http", host: "${HOST}", port: 80]

# Configure your database if needed
config :your_app, YourApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: "${POOL_SIZE}",
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASS}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}"

# ...snip...
