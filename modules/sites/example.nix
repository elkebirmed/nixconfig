# ============================================================================
# Example Site
# A static site built as a flake package and served by Caddy at the apex.
#
# Add another site by adding a `web.sites.<name>` entry in the aspect that owns
# the service; see `modules/aspects/server/web.nix`.
# ============================================================================
{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.example-site = pkgs.writeTextDir "index.html" (builtins.readFile ./example/index.html);
  };

  den.aspects.site-example.nixos = {
    config,
    pkgs,
    ...
  }: {
    web.sites.example = {
      host = config.web.domain;
      access = "public";
      root = "${inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.example-site}";
    };
  };
}
