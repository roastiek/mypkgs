rootDir: { config, lib, pkgs, ... }:

with lib;
{

  enablePHP = true;
  extraApacheModules = [ "mod_rewrite" ];
  DocumentRoot = "${rootDir}/phabricator/webroot";

  options = {
      git = mkOption {
          default = true;
          description = "Enable git repositories.";
      };
      mercurial = mkOption {
          default = true;
          description = "Enable mercurial repositories.";
      };
      subversion = mkOption {
          default = true;
          description = "Enable subversion repositories.";
      };
  };

  phpOptions = ''
    extension=${pkgs.php56Packages.apcu}/lib/php/extensions/apcu.so
    zend_extension=${pkgs.php56}/lib/php/extensions/opcache.so
    always_populate_raw_post_data=-1
    post_max_size=32M

    [opcache]
    opcache.enable=1
    opcache.validate_timestamps=0
  '';

  extraConfig = ''
      DocumentRoot ${rootDir}/phabricator/webroot

      <Directory ${rootDir}/phabricator/webroot>
        Require all granted
      </Directory>

      RewriteEngine on
      RewriteRule ^/rsrc/(.*) - [L,QSA]
      RewriteRule ^/favicon.ico - [L,QSA]
      RewriteRule ^(.*)$ /index.php?__path__=$1 [B,L,QSA]
  '';
}
