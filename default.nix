{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.nebula;
  yamlFormat = pkgs.formats.yaml {};
  nebulaConfig = {
    pki = {
      ca = caCertFiles.crt;
      cert = selfCerts.crt;
      key = selfCerts.key;
    };
    lighthouse = {
      am_lighthouse = true;
      interval = 60;
      hosts = [];
    };
    listen = {
      host = "0.0.0.0";
      port = 4242;
    };
    punchy = {
      punch = true;
      respond = true;
    };
    tun = {
      disabled = false;
      dev = "nebula1";
      drop_local_broadcast = false;
      drop_multicast = false;
      tx_queue = 500;
      mtu = 1300;
      routes = [];
      unsafe_routes = [];
    };
    logging = {
      level = "info";
      format = "text";
    };
    firewall = {
      conntrack = {
        tcp_timeout = "12m";
        udp_timeout = "3m";
        default_timeout = "10m";
        max_connections = 100000;
      };
      outbound = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
      inbound = config.services.nebula.inboundFWRules;
    };
  };
  nebulaConfigYaml = yamlFormat.generate "nebula-config-yaml" nebulaConfig;
  caCertFiles = import ./nebula-ca.nix {
    inherit pkgs;
    name = cfg.hostname;
  };
  selfCerts = import ./nebula-sign.nix {
    inherit caCertFiles pkgs;
    ip = cfg.ipCidr;
    name = cfg.hostname;
  };
in
  {
    options.services.nebula = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "If enabled, NixOS will run nebula as a service.";
      };
      hostname = mkOption {
        type = types.str;
        default = "lighthouse";
        description = "The name of the nebula host in the nebula overlay network.";
      };
      ipCidr = mkOption {
        type = types.strMatching "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+";
        default = "192.168.1.1/24";
        description = "IP and network of the host in CIDR notation.";
      };
      inboundFWRules = mkOption {
        type = with types; listOf (submodule {
          options = {
            port = mkOption {
              type = with types; either str port;
              default = "any";
            };
            proto = mkOption {
              type = str;
              default = "tcp";
            };
            host = mkOption {
              type = str;
              default = "any";
            };
          };
        });
        default = [];
        description = "Inbound firewall rules of nebula";
      };
    };
    config = {
      environment.systemPackages = mkIf cfg.enable [ pkgs.nebula ];
      # environment.etc = mkIf cfg.enable {
      #   "nebula/cluster.yaml" = {
      #     source = nebulaConfigYaml;
      #     mode = "0400";
      #     user = "nebula";
      #     group = "nebula";
      #   };
      #   "nebula/ca.crt" = {
      #     source = caCertFiles + "/ca.crt";
      #     mode = "0400";
      #     user = "nebula";
      #     group = "nebula";
      #   };
      #   "nebula/ca.key" = {
      #     source = caCertFiles + "/ca.key";
      #     mode = "0400";
      #     user = "nebula";
      #     group = "nebula";
      #   };
      # };
      # users.users = mkIf cfg.enable {
      #   nebula = {
      #     name = "nebula";
      #     isSystemUser = true;
      #     createHome = false;
      #     description = "Nebula user";
      #     extraGroups = [ ];
      #   };
      # };
      # users.groups = mkIf cfg.enable {
      #   nebula = {
      #     members = [ "nebula" ];
      #   };
      # };
      systemd.services = mkIf cfg.enable {
        nebula = {
          description = "nebula overlay network";
          script = "${pkgs.nebula}/bin/nebula -config ${nebulaConfigYaml}";
          wants = [ "basic.target" ];
          after = [ "basic.target" "network.target" ];
          reload = "${pkgs.utillinux}/bin/kill -HUP $MAINPID";
          serviceConfig = {
            Restart = "always";
            # User = "nebula";
            # Group = "nebula";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
  }
