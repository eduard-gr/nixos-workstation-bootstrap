{
  description = "GitOps tooling: talosctl, kubectl, helm and friends";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAllSystems (pkgs:
        let
          # helm with plugins baked in (`helm plugin list` shows them).
          helm = pkgs.wrapHelm pkgs.kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-diff # helm diff upgrade ... — preview changes before applying
            ];
          };
        in {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              talosctl
              kubectl
              helm

              k9s         # TUI for the cluster
              kustomize   # standalone kustomize (newer than `kubectl kustomize`)
              kubeconform # validate manifests against k8s schemas
              kubectx     # kubectx / kubens: switch context and namespace
              stern       # tail logs from many pods at once
              yq-go       # YAML processor
              jq          # JSON processor

              pre-commit  # git hooks from .pre-commit-config.yaml
              gitleaks    # secret scanner, used by the gitleaks hook
            ];

            shellHook = ''
              echo "talosctl $(talosctl version --client --short 2>/dev/null | tail -1)"
              echo "kubectl  $(kubectl version --client 2>/dev/null | head -1)"
              echo "helm     $(helm version --short 2>/dev/null)"

              # Install/refresh the git hook on every entry: the hook script
              # records the absolute store path of pre-commit, which changes
              # after `nix flake update`.
              if [ -f .pre-commit-config.yaml ] && git rev-parse --git-dir >/dev/null 2>&1; then
                pre-commit install --install-hooks >/dev/null 2>&1 \
                  || echo "warning: pre-commit install failed, run it manually to see why"
              fi
            '';
          };
      });
    };
}
