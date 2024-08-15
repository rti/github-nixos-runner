{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.stateVersion = "24.05"; # leave at installation release version

  boot.loader.grub = {
    # disko will add all devices that have a EF02 partition
    configurationLimit = 16;
  };

  networking.useDHCP = lib.mkDefault true;

  services.openssh = {
    enable = true;
    openFirewall = true;

    # Do not use RSA host keys, only ed25519. OpenSSH supports ed25519 since 6.5 from 2014
    # https://www.openssh.com/releasenotes.html https://www.openssh.com/txt/release-6.5
    hostKeys = lib.mkForce [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];

    banner = ''
      __        ___ _    _ _                      ____        _ _
      \ \      / (_) | _(_) |__   __ _ ___  ___  / ___| _   _(_) |_ ___
       \ \ /\ / /| | |/ / | '_ \ / _` / __|/ _ \ \___ \| | | | | __/ _ \
        \ V  V / | |   <| | |_) | (_| \__ \  __/  ___) | |_| | | ||  __/
         \_/\_/  |_|_|\_\_|_.__/ \__,_|___/\___| |____/ \__,_|_|\__\___|

      github-runner
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # roti Yubikey 5 Nano
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3jk/XCP/eTLZYWA6vA3higmyVcPQAgLH6Dh/1Zf7SioGApmoETxu3d7IkUt+NujzyJFihg891m3x1V7gOWTQg6KidmdU6V5E2weNgSBnI3V1Vn2TePIn5BmnK6heBiw1hLnzVcDvBIhxVPfsePmGHzt9iYlgrp3bCv1xwsSsZ8yxmPE/O/3TjvIR5XMo+QwUMg1/Xsxx5+aO7qGASwsWIj4NmfEbh9An9vzz++S7f+C//WEY1IFLzM1DmQCFhvVxM+IGZ7eeeT53+SNmfQIMADAgBIdhK1OAtGGffUKvigZBTlIhK3abIKOyUq+WFcncJMn0D/eMlpB7KbphxZPnO9bDU+ODmijCPSpjSZs8bigHweTFjcKiJAzTqUifaWVWjEx/zetnsbiq1jaVhgzZclgiwupZzTbYilEpsTdEOAEICbVnBZqG1QtHmI5YcCudlOhUwnJgFTNwVTMBKKknxTEBiFJMtr62kREOJDeAD/ohpAtOva660dH1zNvfxmUvpbpSwwjp8ngIkCT6JrhCdjBIy2bFqgCtpBTvOxnZnb5nXuMIgTETVPtffD1AuP6vEa/gLyWUhukiTATcX22i2NahOEDS0USRLXYKeB8HCEu3j7J8prf69Md+t+2hY3/BY5mtj28UKG75wTZh/UzDtso1D0GSbaSvZSab91uY4AQ== cardno:23_118_572"
    # roti Yubikey 5C NFC
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsnanR1klGRoD8GCh5vUhXy/R9XGPYSTnwnZK/wXp872tLVgkXLuTgDS1KUw1v58wzM08sATXyy9nprDjMGTkQj4fpiEq6/2hMdaMQ5Dw0FdxU/EFGQebXnNrUAU5yZyu7/kVfu638TuYLTg/fVp5wgT/aOLrpRqq8A2qOQMNcHU9zw0lH4QjcsKaCj9oUcAZtwVlLGeNdtwnaFKE3VtkO+J10Dy5V74xHCwQZLacSbZRNI0wbsIZHqzOVOXugQLU9/8Bl3MQPf3pywUWZeG9A460HZpk1isZSSNAkCkLCcna4qmok5psc6m6UpFWLOZSwnxNn0pYyscyt6NsIlXkxyhN3uR9/ffpE30zYy1zXC5g7tjOuh45FSWG3M0Yudt+Hn0boQVwdxCYg/3WGw2XpOxkGyCnN20ETGp1NzCB8FCctTGqJWWme5VrloU1O2zJ0BcMnkHhouqgpP73f5QttBX6eOQKJ4uV+1cXP9jrlj78cGOwLpnRBZGSRUf50V+BXgV4A+vaQ2bfb4ghfRmfoTLzG4lgPZRHhBbkGhoGDbHjwn5Oc4VGD4EXThkv3dHBCBK4pugeJJR5yWzA+Tv62PFQNE0eg/rrO74jZc4rWRjaweke2j5hkf05GaxlzDjf0KJFW0oR/rGJDkP9m0mu5rwFESoqvEQ1lxAHDjyOErw== cardno:20_560_926"
  ];

  environment.etc."github-runner-token-file".text = "YOURGITHUBRUNNERATTACHTOKEN!!";
  services.github-runners = 
  let 
    tokenFile = "/etc/github-runner-token-file";
    url = "https://github.com/wmde/wikibase-release-pipeline";
  in {
    runner = {
      enable = true;
      name = "${config.networking.hostName}-S4wE";
      inherit tokenFile url;
      user = "github-runner";
      group = "docker";
      extraPackages = [ 

        # tools the actual CI pipeline requires
        pkgs.docker 
        pkgs.gawk 
      ];
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  users.users.github-runner = {
    isSystemUser = true;
    group = "docker";
  };
}
