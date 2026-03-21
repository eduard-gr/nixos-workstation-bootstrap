{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (php83.withExtensions ({ enabled, all }: enabled ++ [
      all.pdo
      all.pdo_pgsql
      all.mbstring
      all.opcache
      all.pgsql
      all.intl
      all.zip
      all.curl
      all.xsl
      all.redis
      all.amqp
    ]))
    php83Packages.composer
  ];
}
