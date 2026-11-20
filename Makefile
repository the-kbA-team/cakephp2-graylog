PHP_VERSION ?= 8.1
DEPENDENCIES_LOWEST ?= 0
COMPOSER_IMAGE ?= composer:2
COMPOSER_CACHE_DIR ?= $(HOME)/.cache/composer
export PHP_VERSION DEPENDENCIES_LOWEST COMPOSER_IMAGE COMPOSER_CACHE_DIR

.PHONY: help clean check-php-version install lint test analyze audit validate check

help:
	@printf '%s\n' \
		'check       Install, lint, test, analyze and audit one dependency snapshot' \
		'install     Install dependencies without retaining composer.lock' \
		'lint        Check PHP syntax' \
		'test        Run PHPUnit and write clover.xml coverage' \
		'analyze     Run PHPStan' \
		'audit       Resolve and audit a new dependency snapshot' \
		'validate    Validate composer.json' \
		'clean       Remove generated vendor, coverage and PHPUnit cache files' \
		'Set PHP_VERSION and optionally DEPENDENCIES_LOWEST=1.'

check-php-version:
	@case "$(PHP_VERSION)" in 8.[1-9]|8.[1-9][0-9]) ;; \
		*) echo "PHP_VERSION must be a supported PHP 8 minor version (8.1 or later)." >&2; exit 1 ;; esac

clean:
	rm -rf vendor .phpunit.result.cache clover.xml

install lint test analyze audit validate check: check-php-version
	@sh tools/qa.sh $@
