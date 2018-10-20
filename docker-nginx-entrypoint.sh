#!/bin/sh
set -e

if [ "${1#-}" != "$1" ]; then
	set -- nginx "$@"
fi

confd -onetime -backend env

exec "$@"