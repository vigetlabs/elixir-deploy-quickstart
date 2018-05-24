# Setup app

## Distillery

[Add Distillery to your project](https://hexdocs.pm/distillery/getting-started.html)

[Understand how to configure](https://hexdocs.pm/distillery/runtime-configuration.html)

[If you're using Phoenix, read the guide](https://hexdocs.pm/distillery/use-with-phoenix.html)
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
  - [rel/commands/migrate.sh](./rel/commands/migrate.sh)
  - [rel/config.exs](./rel/config.exs)
- [priv/repo/seeds.exs](./priv/repo/seeds.exs) Sample seed file. All of
    it is commented out, but you can get an idea of what real seeds look
    like.

Copy these to your project and customize for your app needs.

# Setup Server

This guide was made with Ubuntu 18.04 on DigitalOcean. Your mileage may
vary if you use a different OS or SaaS.

## Create user

```shell
## ssh root@your_server
## At this point, everything is on the server, not your local machine
#> adduser deploy sudo
#> usermod -aG sudo deploy
#> find .ssh -print | cpio -pdmv --owner=deploy ~deploy
#> sudo su - deploy
$> mkdir -p your_app/postgres_backups
```

## HTTP server

[Sample nginx config](./nginx-config)

```shell
$ sudo apt-get install nginx
$ sudo vim /etc/nginx/sites-available/your_app
$ # paste nginx config stuff
$ sudo ln -s /etc/nginx/sites-available/your_app /etc/nginx/sites-enabled/your_app
$ sudo rm /etc/nginx/sites-enabled/default
$ # validate the nginx config
$ sudo nginx -c /etc/nginx/nginx.conf -t
$ sudo systemctl restart nginx
```

The sample nginx config is not fit for real production usage. This will
get you started, but you should definitely setup SSL and HTTPS.

Follow [Digital Ocean's guide] for enabling SSL, and make sure You
update the server config in `config/prod.exs`

[Digital Ocean's guide]: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04

## Systemd Service

[Distillery guide](https://hexdocs.pm/distillery/use-with-systemd.html)
[Sample systemd unit](./systemd.service)

```shell
$ sudo vim /etc/systemd/service/yourapp.service
$ # paste some stuff
$ sudo systemctl enable your_app
```

## Postgres

```shell
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
# ~/.bashrc
export DB_HOST=localhost
export DB_NAME=your_app
export DB_PASS=shh
export DB_USER=deploy
export HOST=localhost
export LANG=en_US.UTF-8
export MIX_ENV=prod
# Leaves you with 5 extra connections for other things
# Postgres defaults to having 100 connections available
export POOL_SIZE=95
export PORT=4000
export REPLACE_OS_VARS=true
export SECRET_KEY_BASE=1234
```

Make sure you use a real `SECRET_KEY_BASE` output from `mix
phx.gen.secret`.

## Password-less `sudo` for deploy and release script

This will ensure that `bin/release.sh` can restart your app without
being prompted for a password.

```shell
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
