# Setup app

## Distillery

[Add Distillery to your project](https://hexdocs.pm/distillery/introduction/installation.html)

[Understand how to configure](https://hexdocs.pm/distillery/runtime-configuration.htmlhttps://hexdocs.pm/distillery/config/runtime.html)

[If you're using Phoenix, read the guide](https://hexdocs.pm/distillery/guides/phoenix_walkthrough.html)
Ignore the part about {:system, "PORT"} if you're using Phoenix >=1.3.
Instead, look at this [prod.exs](config/prod.exs) snippet.

The scripts contained in this quickstart guide wrap up a lot of
Distillery's guide into scripts.

- [bin/setup.sh](./bin/setup.sh)
- [bin/setup_assets.sh](./bin/setup_assets.sh)
- [bin/build_release.sh](./bin/build_release.sh)
- [bin/release.sh](./bin/release.sh)
- Pull some Distillery scripts:
  - Don't use the docs on hexdocs, it's outdated and doesn't work as
      of 20180524. These samples were pulled from
      [master](https://github.com/bitwalker/distillery/blob/fa6777fdc0c61aa8fcad54ffaabbb6829dd4fb38/docs/guides/running_migrations.md).
  - [lib/your_app/release_tasks.ex](./lib/your_app/release_tasks.ex).
  - [rel/commands/migrate.sh](./rel/commands/migrate.sh) There is a
      difference here where the `env.prod` file is sourced to get the
      secrets in the environment before running the command.
  - [rel/config.exs](./rel/config.exs)
- [priv/repo/seeds.exs](./priv/repo/seeds.exs) Sample seed file. All of
    it is commented out, but you can get an idea of what real seeds look
    like.

Copy these to your project and customize for your app needs.

# Setup Server

This guide was made with Ubuntu 18.04 on DigitalOcean. Your mileage may
vary if you use a different OS or SaaS.

## Create user

```console
# # ssh root@your_server
# # At this point, everything is on the server, not your local machine
# adduser deploy sudo
# usermod -aG sudo deploy
# find .ssh -print | cpio -pdmv --owner=deploy ~deploy
# sudo su - deploy
$ mkdir -p your_app/postgres_backups
$ mkdir -p your_app/config
```

## HTTP server

[Sample nginx config](./nginx-config)

```console
$ sudo apt-get install nginx
$ sudo vim /etc/nginx/sites-available/your_app
$ # paste nginx config stuff
$ sudo ln -s /etc/nginx/sites-available/your_app /etc/nginx/sites-enabled/your_app
$ sudo rm /etc/nginx/sites-enabled/default
$ # validate the nginx config
$ sudo nginx -c /etc/nginx/nginx.conf -t
$ sudo systemctl restart nginx
```

The sample nginx config is not fit for production usage. This will get
you started, but you should definitely setup SSL and HTTPS.

Follow [Digital Ocean's guide] for enabling SSL, and make sure You
update the server config in `config/prod.exs`

[Digital Ocean's guide]: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04

## Systemd Service

[Distillery guide](https://hexdocs.pm/distillery/use-with-systemd.html)

[Sample systemd unit](./systemd.service)

```console
$ sudo vim /etc/systemd/service/yourapp.service
$ # paste some stuff
$ sudo systemctl enable your_app
```

## Postgres

```console
$ sudo apt-get install postgresql postgresql-contrib
$ sudo su - postgres
$ createdb your_app
$ psql
```

```sql
CREATE ROLE deploy WITH superuser;
ALTER ROLE deploy WITH createdb;
ALTER ROLE deploy WITH login;
ALTER USER deploy WITH PASSWORD 'shh';
-- ctrl+d to exit
```

Please don't use `shh` as your password :\

## Copy secrets over

```bash
# ~/your_app/config/env.prod
LANG=en_US.UTF-8
MIX_ENV=prod
REPLACE_OS_VARS=true
RELEASE_NAME=your_app_production

# If you're using Phoenix, you'll need these:
HOST=localhost
SECRET_KEY_BASE=1234
PORT=4000

# if you're using Ecto, you'll need these:
DB_HOST=localhost
DB_NAME=your_app
DB_PASS=shh
DB_PORT=5432
DB_USER=deploy
POOL_SIZE=95
# 95 leaves you with 5 extra connections for other processes
# Postgres defaults to having 100 connections available
```

Make sure you use a real `SECRET_KEY_BASE` output from `mix
phx.gen.secret`.

## Password-less `sudo` for deploy and release script

This will ensure that `bin/release.sh` can restart your app without
being prompted for a password.

```console
$ sudo visudo
```

Then append to the end:

```
deploy ALL=NOPASSWD: /bin/systemctl start your_app
deploy ALL=NOPASSWD: /bin/systemctl stop your_app
deploy ALL=NOPASSWD: /bin/systemctl restart your_app
```

Write to file and exit.

# Compiling your app for release locally using Docker

See [Dockerfile](./Dockerfile). The goal is to setup a local container
that matches your production environment as closely as possible. In this
quickstart, we're using Ubuntu 18.04, so the Dockerfile will pull from
that default Ubuntu image.

The Dockerfile also has two options for building the environment:

1. Using asdf to manage versions. This is slow because it builds erlang
   from source. But it's nice because developers can manage the
   tool-versions once with `.tool-versions`
1. Using Erlang Solutions pre-built binaries from their apt-source. This
   speeds up the build process, but also means you have to specify the
   tool versions in the Dockerfile again, as well as your
   `.tool-versions`.

Play with this to see what fits your style and app best.

How to release:

1. Follow the sections above
1. Make sure all the scripts in this quickstart guide are modified for
   your app.
1. run [bin/release.sh](./bin/release.sh). When prompted, enter the
   release version that distillery built. It should be mentioned in the
   stdout above the prompt.



# FAQ

### I have two instances of the app running on the same server. Will this
work?

The `RELEASE_NAME` environment variable will be the nodename of that
release, and it's required for that name to be unique. When you have
both instances on the server, edit the `env.prod` file for a given
instance and make sure it's unique.

### I don't want to source the environment file before every command

is there a way to automatically do that? I keep forgetting to use
`REPLACE_OS_VARS=true` and add my database credentials?

Yes! I feelz ya. One way is to add a Distillery plugin that creates a
custom `boot_check` script. In this script, copy the [default boot_check
template] into `rel/templates/boot_check.eex`, but add something like
this before it loads the app:

```bash
# /rel/templates/boot_check.eex

... snip ...
. "${SCRIPT_DIR}/../config/env.prod"
export REPLACE_OS_VARS=true

... snip ...
```

Then create the Distillery plugin that uses this custom boot check template:

```elixir
defmodule YourApp.Release.CustomBootCheck do
  use Mix.Releases.Plugin

  def before_assembly(_release, _opts), do: nil

  def after_assembly(_release, _opts), do: nil

  def before_package(%Release{} = release, template: template) do
    info "Generating custom executable.."

    executable =
      EEx.eval_file(template, [release_name: release.name,
                               exec_options: release.profile.exec_opts])

    bin_path = Path.join(release.profile.output_dir, "bin")

    File.write!(Path.join(bin_path, Atom.to_string(release.name)), executable)

    release
  end

  def after_package(_release, _opts), do: nil

  def after_cleanup(_args, _opts), do: nil
end
```

Finally, tell Distillery to use the plugin:

```elixir
# rel/config.exs

plugin YourApp.Release.CustomBootCheck, template: "rel/templates/boot_check.eex"
```

[boot_check]: https://github.com/bitwalker/distillery/blob/master/priv/templates/boot_check.eex
