# NixOS Github Runners

Automatically setup github-runners using OpenTofu to rent machines from Hetzner and nixos-anywhere & disko to deploy NixOS.

A nix shell provides the following commands:

```
    provision  - rent servers from hetzner
    bootstrap  - install nixos and deploy configuration
    deploy     - redeploy configuration
    shell      - ssh into machines using tmux
```
