{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Runtime + package managers. nodejs (24 LTS) ships npm and npx.
    nodejs
    yarn            # yarn classic 1.x; use yarn-berry for yarn 4
    pnpm

    # TypeScript compiler + language servers (ts/js, html/css/json/eslint)
    # so Zed and other editors have them without a per-project install.
    typescript
    vtsls                        # Zed's default TS/JS server
    typescript-language-server
    vscode-langservers-extracted

    # Formatting / linting; project-local versions take precedence
    # when a project pins its own in node_modules.
    prettier
    eslint
  ];
}
