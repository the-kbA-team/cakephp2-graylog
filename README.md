# CakePHP 2 Graylog

[![License: MIT][license-mit]](LICENSE)

Graylog log engine for CakePHP 2.x

## Usage

```bash
composer require kba-team/cakephp2-graylog
```

The package must be published to Packagist before this command works. To
migrate from `kba-team/cakephp-graylog`, remove the old dependency and require
this package in the same Composer update. Both packages install the `Graylog`
plugin and must not be installed together. The plugin configuration below is
unchanged; PHP 8.1 or later is required.

```php
<?php
CakePlugin::load('Graylog');
CakeLog::config('graylog', [
    'engine' => 'Graylog.Graylog',
    'types' => ['warning', 'error', 'critical', 'alert', 'emergency'], //PSR log levels
    'host' => 'graylog.example.com',
    'port' => 12201,
    'facility' => 'MyAppName',
    'append_backtrace' => true, //append a complete backtrace to the message body
    'append' => [
        //append the contents of $_POST JSON encoded to the message body
        'POST' => static function () {
             if (!empty($_POST)) {
                $obfuscator = new \kbATeam\GraylogUtilities\Obfuscator();
                //Replace the value of all keys named 'password' with 'xxx'.
                $obfuscator->addKey('password');
                $obfuscator->setObfuscationString('xxx');
                //JSON encode the POST variable for readability.
                return json_encode(
                    $obfuscator->obfuscate($_POST),
                    JSON_PRETTY_PRINT
                );
             }
             return null;
        }
    ],
    'additional' => [
        //Add field 'current_user' to the GELF message.
        'current_user' => static function () {
             return 'system';
        }
    ]
]);
```

Possible configuration parameters are:
* `scheme` Currently TCP or UDP connections to Graylog are supported. Default: `udp`
* `host` The hostname of the Graylog server. Default: `127.0.0.1`
* `port` The port, the Graylog server listens to. Default: `12201`
* `url` A connection URL in format `<scheme>://<host>:<port>`. This will overwrite any other settings.
* `ignore_transport_errors` Ignore transport errors Default: `true`
* `chunk_size` The size of the UDP packages. Default: `\Gelf\Transport\UdpTransport::CHUNK_SIZE_LAN`
* `ssl_options` An instance of `\Gelf\Transport\SslOptions` defining SSL settings for TCP connections. Default: `null`
* `facility` The logging facility. Default: `CakePHP`.
* `append_backtrace` Append a backtrace to the message body? Default: `false`
* `append` Array of anonymous functions. Their return strings get appended to the message body.
* `additional` Array of anonymous functions. Their return values get added as additional fields to the GELF message.
* `types` Array of log types, that will be sent to Graylog. See `\Psr\Log\LogLevel` for all possible values. Default: all of them.

## Development

The package supports PHP `^8.1` and tests PHP 8.1 and 8.5 with both default
and lowest dependency versions. PHP 8.0 is no longer supported. Docker and
network access are required.

```sh
make help
make validate PHP_VERSION=8.1
make check PHP_VERSION=8.1
make check PHP_VERSION=8.1 DEPENDENCIES_LOWEST=1
make check PHP_VERSION=8.5
make check PHP_VERSION=8.5 DEPENDENCIES_LOWEST=1
```

`check` installs dependencies, runs lint, PHPUnit with Clover coverage and
PHPStan, then audits the same dependency snapshot. `test` and `check` write
`clover.xml`. `install` and `audit` resolve their own snapshots.
These commands refuse to overwrite an existing `composer.lock` and remove
their temporary lockfile. `make clean` removes generated `vendor/`, coverage and
PHPUnit cache files. Set `COMPOSER_IMAGE` to select the Composer image, and set proxy
variables and `CA_CERT_FILE` if your network requires them.

Use an issue branch named `<issue-number>-<title-slug>` and open a pull request
against the relevant release branch. The `main` branch requires a pull request,
passing checks, an up-to-date branch and linear history; use squash merge.
The CakePHP 5 release line is maintained in
[`the-kbA-team/cakephp-graylog`](https://github.com/the-kbA-team/cakephp-graylog).
Force pushes are blocked outside branch names matching `[0-9]*-*`; this
pattern is broader than the issue-branch naming convention.

### Further reading

* About [CakePHP 2.x Logging](https://book.cakephp.org/2/en/core-libraries/logging.html)
* About [Graylog 3.x in general](https://docs.graylog.org/en/3.1/index.html)
* About [Graylog Extended Log Format (GELF)](https://docs.graylog.org/en/3.1/pages/gelf.html)

[license-mit]: https://img.shields.io/badge/license-MIT-blue.svg
