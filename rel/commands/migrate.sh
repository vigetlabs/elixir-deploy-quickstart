#!/bin/sh

. /home/deploy/your_app/config/env.prod

REPLACE_OS_VARS=true "$RELEASE_ROOT_DIR"/bin/your_app command Elixir.YourApp.ReleaseTasks seed
