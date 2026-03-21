{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    php83
    php83Packages.composer
    php83Extensions.pdo
    php83Extensions.pdo_pgsql
    php83Extensions.mbstring
    php83Extensions.opcache
    php83Extensions.pgsql
    php83Extensions.intl
    php83Extensions.zip
    php83Extensions.curl
    php83Extensions.xsl
    php83Extensions.xsl
    php83Extensions.redis
    php83Extensions.amqp
  ];
}
