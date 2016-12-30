{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.phabricator;

  jsonConfig = builtins.toJSON {
      "phd.user" = "phd";
      "pygments.enabled" = true;
      "phabricator.base-uri" = "http://bobo-machine.lan/";
      "phd.pid-directory" = "/run/phd";
      "phd.log-directory" = "/var/log/phd";
      "diffusion.ssh-user" = "vcs";
      "diffusion.allow-http-auth" = true;
      "environment.append-paths" = [
        "/var/setuid-wrappers"
        "${pkgs.which}/bin"
        "${pkgs.git}/bin"
        "${pkgs.diffutils}/bin"
        "${pkgs.python3Packages.pygments}/bin"
        "${pkgs.mysql}/bin"
        "${pkgs.php56}/bin"
        "${pkgs.ctagsWrapped.ctagsWrapped}/bin"
        "${pkgs.openssh}/bin"
      ];
      "search.elastic.host" = "http://localhost:9200/";
    };

  localConfig = pkgs.writeText "local.json" jsonConfig;

  rootDir = pkgs.runCommand "phabricator" { buildInputs = [ pkgs.makeWrapper ];} ''
    mkdir -p $out
    cp -R ${pkgs.libphutil-src} $out/libphutil
    cp -R ${pkgs.arcanist-src} $out/arcanist
    cp -R ${pkgs.phabricator-src} $out/phabricator
    chmod u+w -R $out
    ln -s ${localConfig} $out/phabricator/conf/local/local.json
  '';

  ssh-hook = pkgs.writeScript "phabricator-ssh-hook" ''
    #! ${pkgs.stdenv.shell}

    VCSUSER="vcs"
    if [ "$1" != "$VCSUSER" ];
    then
      exit 1
    fi

    exec "${rootDir}/phabricator/bin/ssh-auth" $@
  '';

in
{
  options = {
    services.phabricator = {
      enable = mkOption  {
        default = false;
        type = types.bool;
        description = "";
      };

      config = mkOption {
        default = { };
        description = "";
      };

      runDir = mkOption {
        default = "/run/phabricator";
        type = types.string;
        description = "";
      };
    };
  };

  config = mkIf cfg.enable {
    users.extraUsers.phd = {
      name = "phd";
      group = "phd";
      uid = config.ids.uids.phd;
    };

    users.extraGroups.phd = {
      name = "phd";
      gid = config.ids.gids.phd;
    };

    users.extraUsers.vcs = {
      name = "vcs";
      group = "vcs";
      uid = config.ids.uids.vcs;
      hashedPassword = "NP";
      shell = "/run/current-system/sw/bin/sh";
    };

    users.extraGroups.vcs = {
      name = "vcs";
      gid = config.ids.gids.vcs;
    };

    security.sudo.extraConfig = ''
      wwwrun ALL=(pdh) SETENV: NOPASSWD: ${pkgs.git}/bin/git, ${pkgs.git}/bin/git-http-backend
      vcs ALL=(phd) SETENV: NOPASSWD: ${pkgs.git}/bin/git, ${pkgs.git}/bin/git-upload-pack, ${pkgs.git}/bin/git-receive-pack
    '';

    services.mysql.enable = true;
    #services.mysql.package = pkgs.mysql;
    services.mysql.extraArgs = "--sql-mode=STRICT_ALL_TABLES";
    services.mysql.extraOptions = ''
      max_allowed_packet = 33554432
    '';

    services.httpd.enable = true;
    services.httpd.phpPackage = pkgs.php56;
    services.httpd.virtualHosts = [{
      extraSubservices = [
        { function = (import ./phabricator-httpd.nix rootDir); }
      ];
    }];

    systemd.services.httpd.serviceConfig.TimeoutSec=5;

    services.openssh.enable = true;
    services.openssh.extraConfig = ''
      Match User vcs
          AuthorizedKeysCommand /run/phabricator-ssh-hook
          AuthorizedKeysCommandUser vcs
    '';

    system.activationScripts.phabricator = ''
      echo "setting up phabricator"
      cp ${ssh-hook} /run/phabricator-ssh-hook
      mkdir -m 0750 -p /var/log/phd
      chown phd:phd -R /var/log/phd
      mkdir -m 0750 -p /var/repo
      chown phd:phd -R /var/repo
    '';

    systemd.services.phabricator-storage-upgrade = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${rootDir}/phabricator/bin/storage upgrade --force";
        RemainAfterExit = "yes";
      };

      wantedBy = [ "multi-user.target" ];
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
      before = [ "httpd.service" "phd.service" ];
    };

    systemd.services.phabricator-init-index = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${rootDir}/phabricator/bin/search init";
        RemainAfterExit = "yes";
      };

      wantedBy = [ "multi-user.target" ];
      after = [ "elasticsearch.service" ];
      requires = [ "elasticsearch.service" ];
      before = [ "httpd.service" "phd.service" ];
    };

    systemd.services.phabricator-clear-cache = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = ''
        echo "use phabricator_cache; delete from cache_general where cacheKey = 'phabricator:ssh.authfile'" | ${rootDir}/phabricator/bin/storage shell
      '';

      wantedBy = [ "multi-user.target" ];
      after = [ "mysql.service" "phabricator-storage-upgrade.service" ];
      requires = [ "mysql.service" ];
    };

    systemd.services.phd = {
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${rootDir}/phabricator/bin/phd start";
        ExecStop = "${rootDir}/phabricator/bin/phd stop";
        User = "phd";
        Group = "phd";
        RestartSec = "30s";
        Restart = "always";
        StartLimitInterval = "1m";
        RuntimeDirectory = "phd";
        PermissionsStartOnly = true;
        Type = "forking";
      };

    };

    services.elasticsearch.enable = true;
    services.elasticsearch.package = pkgs.elasticsearch;
  };
}
