{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere/1.1.0";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/v1.3.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ inputs: 
  let
      system = "x86_64-linux";

      pkgs = (import nixpkgs) {
        inherit system;
      };

      specialArgs = {
        inherit inputs;
      };

      # ALWAYS sync with machineCount in main.tf
      machineCount = 6;

      hostnames = builtins.genList (n: "github-runner-${toString (n+1)}") machineCount;

      mkSystemConfig = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        inherit specialArgs;
        modules = [
          inputs.disko.nixosModules.disko
          (import ./disko-config.nix)
          ./configuration.nix
          ({ ... }: {
            networking.hostName = hostname;
          })
        ];
      };

    in
    {

      nixosConfigurations = nixpkgs.lib.genAttrs hostnames (hostname: mkSystemConfig hostname);

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          inputs.disko.packages.x86_64-linux.disko
          inputs.nixos-anywhere.packages.x86_64-linux.nixos-anywhere
          (pkgs.opentofu.withPlugins (p: [ p.hcloud ]))
          pkgs.tmux


          (pkgs.writeShellScriptBin "provision" ''
            set -e
            tofu init -reconfigure
            tofu apply -var "hcloud_token=$(pass hetzner.com/wbs-gitlab-runner-api-token)"
          '')

          (pkgs.writeShellScriptBin "bootstrap" ''
            set -e
            for file in ./public-ipv4-*; do
              server_ip=$(cat "$file")
              server_number=$(echo $file | sed 's/.*-\([0-9]\+\)$/\1/')
              server_name="github-runner-''${server_number}"
              nixos-anywhere --flake ".#''${server_name}" "root@''${server_ip}"
            done
          '')


          (pkgs.writeShellScriptBin "deploy" ''
            set -e
            for file in ./public-ipv4-*; do
              server_ip=$(cat "$file")
              server_number=$(echo $file | sed 's/.*-\([0-9]\+\)$/\1/')
              server_name="github-runner-''${server_number}"
              nixos-rebuild switch --flake ".#''${server_name}" \
                --target-host root@"''${server_ip}" --use-substitutes
            done
          '')

          (pkgs.writeShellScriptBin "shell" ''
            set -e

            tmux new-session -d -s servers

            for file in ./public-ipv4-*; do
              server_ip=$(cat "$file")
              tmux split-window -h "ssh root@''${server_ip}"
              tmux select-layout tiled
            done

            tmux select-pane -t 0
            tmux kill-pane

            tmux setw synchronize-panes on

            tmux attach-session -t servers
          '')

        ];

        shellHook = ''
        cat <<EOF

        provision  - buy servers
        bootstrap  - install nixos and deploy configuration
        deploy     - redeploy configuration to nixos
        shell      - ssh into machines using tmux

        EOF
        '';
      };
    };
}
