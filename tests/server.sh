#!/usr/bin/env bash
# Starts or stops the Mailpit servers the integration tests send to: one that speaks plain SMTP
# and offers STARTTLS, and one that only accepts TLS from the first byte, both with a
# self-signed certificate generated here. Mailpit shows what it received through an HTTP API.
# Reverse DNS is off: a lookup that cannot finish would hold every greeting back for seconds.
set -e

NAME=valk-smtp-mailpit
TLS_NAME=valk-smtp-mailpit-tls
IMAGE=${MAILPIT_IMAGE:-axllent/mailpit:v1.31.2}
CERTS="$(cd "$(dirname "$0")" && pwd)/certs"

# Waits until the HTTP API of a server answers
wait_for() {
    for _ in $(seq 1 60); do
        if curl -sf "http://127.0.0.1:$1/api/v1/info" >/dev/null 2>&1; then return 0; fi
        sleep 0.5
    done
    echo "mailpit on port $1 did not start" >&2
    exit 1
}

case "${1:-up}" in
    up)
        if [ ! -f "${CERTS}/server.crt" ]; then
            mkdir -p "${CERTS}"
            openssl req -new -x509 -days 3650 -nodes -subj "/CN=localhost" \
                -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
                -keyout "${CERTS}/server.key" -out "${CERTS}/server.crt" 2>/dev/null
            chmod 644 "${CERTS}/server.key"
        fi

        # SMTP on 2525 with STARTTLS on offer, the API on 8525
        if [ -n "$(docker ps -aq -f name=^${NAME}$)" ]; then
            docker start ${NAME} >/dev/null
        else
            docker run -d --name ${NAME} -p 2525:1025 -p 8525:8025 \
                -v "${CERTS}":/certs:ro ${IMAGE} \
                --smtp-tls-cert /certs/server.crt --smtp-tls-key /certs/server.key \
                --smtp-auth-accept-any --smtp-auth-allow-insecure \
                --smtp-disable-rdns --disable-version-check >/dev/null
        fi

        # SMTP over TLS from the first byte on 2465, the API on 8526
        if [ -n "$(docker ps -aq -f name=^${TLS_NAME}$)" ]; then
            docker start ${TLS_NAME} >/dev/null
        else
            docker run -d --name ${TLS_NAME} -p 2465:1025 -p 8526:8025 \
                -v "${CERTS}":/certs:ro ${IMAGE} \
                --smtp-tls-cert /certs/server.crt --smtp-tls-key /certs/server.key \
                --smtp-require-tls --smtp-auth-accept-any \
                --smtp-disable-rdns --disable-version-check >/dev/null
        fi

        wait_for 8525
        wait_for 8526
        echo "mailpit: SMTP with STARTTLS on 127.0.0.1:2525 (web and API on http://127.0.0.1:8525)"
        echo "mailpit: SMTP over TLS on 127.0.0.1:2465 (web and API on http://127.0.0.1:8526)"
        ;;
    down)
        docker rm -f ${NAME} ${TLS_NAME} >/dev/null 2>&1 || true
        rm -rf "${CERTS}"
        echo "removed the test servers"
        ;;
    *)
        echo "usage: $0 [up|down]" >&2
        exit 1
        ;;
esac
