#!/bin/sh
set -eu

task=${1:?Missing QA task}
php_version=${PHP_VERSION:-8.1}
lowest=${DEPENDENCIES_LOWEST:-0}

case "$task" in
    install|check|audit|validate|lint|test|analyze) ;;
    *) echo "Unknown QA task: $task" >&2; exit 1 ;;
esac
case "$lowest" in 0|1) ;; *) echo "DEPENDENCIES_LOWEST must be 0 or 1." >&2; exit 1 ;; esac

if [ "${QA_NATIVE:-0}" != 1 ]; then
    case "$task" in
        install|check|audit)
            if [ -e composer.lock ]; then
                echo "Refusing to overwrite an existing composer.lock." >&2
                exit 1
            fi
            ;;
    esac

    tmp=$(mktemp -d)
    container=
    cleanup() {
        status=$?
        trap - EXIT HUP INT TERM
        if [ -n "$container" ]; then
            docker rm "$container" >/dev/null || { echo "Failed to remove Composer container." >&2; [ "$status" -ne 0 ] || status=1; }
        fi
        rm -f "$tmp/composer" || { echo "Failed to remove temporary Composer binary." >&2; [ "$status" -ne 0 ] || status=1; }
        rmdir "$tmp" || { echo "Failed to remove temporary directory." >&2; [ "$status" -ne 0 ] || status=1; }
        case "$task" in
            install|check|audit)
                rm -f composer.lock || { echo "Failed to remove temporary composer.lock." >&2; [ "$status" -ne 0 ] || status=1; }
                ;;
        esac
        exit "$status"
    }
    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    image=${COMPOSER_IMAGE:-composer:2}
    composer_path=$(docker run --rm --entrypoint sh "$image" -c 'command -v composer')
    container=$(docker create --entrypoint sh "$image" -c 'exit 0')
    docker cp "$container:$composer_path" "$tmp/composer"
    docker rm "$container" >/dev/null
    container=
    chmod a+r "$tmp/composer"
    chmod a+rx "$tmp"
    mkdir -p "${COMPOSER_CACHE_DIR:?Missing Composer cache directory}"

    set -- docker run --rm --init \
        --volume "$PWD:/app" --workdir /app \
        --volume "$tmp/composer:/usr/local/bin/composer:ro" \
        --volume "$COMPOSER_CACHE_DIR:/composer-cache" \
        --env COMPOSER_CACHE_DIR=/composer-cache --env HOME=/tmp \
        --env COMPOSER_AUTH \
        --env HTTP_PROXY --env HTTPS_PROXY --env NO_PROXY \
        --env http_proxy --env https_proxy --env no_proxy \
        --env PHP_VERSION="$php_version" --env DEPENDENCIES_LOWEST="$lowest" \
        --env QA_NATIVE=1 --env HOST_UID="$(id -u)" --env HOST_GID="$(id -g)"
    if [ -n "${CA_CERT_FILE:-}" ]; then
        [ -f "$CA_CERT_FILE" ] || { echo "CA_CERT_FILE is not a file." >&2; exit 1; }
        set -- "$@" --volume "$CA_CERT_FILE:/usr/local/share/ca-certificates/extra-ca.crt:ro"
    fi
    "$@" "php:$php_version-cli" sh -ec '
        if [ -f /usr/local/share/ca-certificates/extra-ca.crt ]; then
            update-ca-certificates >/dev/null
        fi
        apt-get update -qq -o APT::Update::Error-Mode=any
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl git unzip libicu-dev >/dev/null
        docker-php-ext-install intl >/dev/null
        curl -fsSL https://pecl.php.net/get/pcov-1.0.12.tgz -o /tmp/pcov.tgz
        pecl install /tmp/pcov.tgz >/dev/null
        docker-php-ext-enable pcov
        exec setpriv --reuid="$HOST_UID" --regid="$HOST_GID" --clear-groups sh tools/qa.sh '"$task"'
    '
    exit
fi

actual=$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')
if [ "$actual" != "$php_version" ]; then
    echo "Expected PHP $php_version, got PHP $actual." >&2
    exit 1
fi

lint() {
    find Lib tests -type f -name '*.php' -exec sh -c 'for file do php -l "$file" || exit; done' sh {} +
}

test_with_coverage() {
    php -r 'if (!extension_loaded("pcov") && !extension_loaded("xdebug")) { fwrite(STDERR, "A PHP coverage driver is required.\n"); exit(1); }'
    rm -f clover.xml
    php vendor/bin/phpunit --do-not-cache-result --coverage-clover clover.xml
    if [ ! -s clover.xml ]; then
        echo "PHPUnit did not produce the Clover coverage report." >&2
        return 1
    fi
}

cleanup_lock() {
    status=$?
    trap - EXIT HUP INT TERM
    rm -f composer.lock || { echo "Failed to remove temporary composer.lock." >&2; [ "$status" -ne 0 ] || status=1; }
    exit "$status"
}

resolve() {
    if [ -e composer.lock ]; then
        echo "Refusing to overwrite an existing composer.lock." >&2
        exit 1
    fi
    trap cleanup_lock EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if [ "$lowest" = 1 ]; then
        composer update --prefer-lowest --prefer-dist --no-interaction --no-progress
    else
        composer update --prefer-dist --no-interaction --no-progress
    fi
}

case "$task" in
    validate) composer validate --strict --no-check-lock ;;
    lint) lint ;;
    test) test_with_coverage ;;
    analyze) php vendor/bin/phpstan analyse --no-progress ;;
    install) resolve ;;
    audit) resolve; composer audit ;;
    check)
        resolve
        lint
        test_with_coverage
        php vendor/bin/phpstan analyse --no-progress
        composer audit
        ;;
    *) echo "Unknown QA task: $task" >&2; exit 1 ;;
esac
