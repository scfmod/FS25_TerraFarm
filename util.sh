#!/bin/sh
M_PWD="$PWD" bun run --env-file "$PWD/.env" --env-file .env --silent --cwd ../../FS22/FS22_ModUtils "$@"
