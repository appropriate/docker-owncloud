#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
	tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
	chown -R www-data /var/www/html
fi

if [[ "$1" = apache2* ]]; then
	: ${OWNCLOUD_TLS_CERT:=$OWNCLOUD_SSL_CERT}
	: ${OWNCLOUD_TLS_KEY:=$OWNCLOUD_SSL_KEY}

	if [ "$OWNCLOUD_TLS_CERT" -o "$OWNCLOUD_TLS_KEY" ]; then
		if [ -z "$OWNCLOUD_TLS_CERT" -o -z "$OWNCLOUD_TLS_KEY" ]; then
			echo >&2 "ERROR: Both OWNCLOUD_TLS_CERT and OWNCLOUD_TLS_KEY must be provided to enable HTTPS"
			exit 1
		fi

		if ! [ -f "$OWNCLOUD_TLS_CERT" -o -f "/etc/ssl/certs/$OWNCLOUD_TLS_CERT" ]; then
			echo >&2 "ERROR: TLS certificate '$OWNCLOUD_TLS_CERT' not found"
			exit 1
		elif ! [ -f "$OWNCLOUD_TLS_CERT" ]; then
			export OWNCLOUD_TLS_CERT="/etc/ssl/certs/$OWNCLOUD_TLS_CERT"
		fi

		if ! [ -f "$OWNCLOUD_TLS_KEY" -o -f "/etc/ssl/private/$OWNCLOUD_TLS_KEY" ]; then
			echo >&2 "ERROR: TLS key '$OWNCLOUD_TLS_KEY' not found"
			exit 1
		elif ! [ -f "$OWNCLOUD_TLS_KEY" ]; then
			export OWNCLOUD_TLS_KEY="/etc/ssl/private/$OWNCLOUD_TLS_KEY"
		fi

		a2enmod ssl
		a2ensite owncloud-ssl
	else
		cat >&2 <<-'EOWARN'
		WARNING: Running ownCloud without HTTPS is not recommended.
		         See the documentation for information on enabling HTTPS:

			 https://github.com/docker-library/docs/tree/master/owncloud
		EOWARN
	fi
fi

exec "$@"
