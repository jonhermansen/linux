{
  description = "Linux kernel — buildable on aarch64/x86_64 darwin/linux; targets host arch for fastest virt";

  inputs.nixpkgs.url = "path:/Users/user/work/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      perSystem = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Cross-built Linux package set — same CPU as the host, Linux
          # kernel, glibc. Works for any CPU nixpkgs supports without
          # enumeration. We use this for *all* Linux-targeted derivations
          # so there's a single, consistent build mode.
          pkgsCrossLinux = import nixpkgs {
            inherit system;
            crossSystem = {
              config = "${pkgs.stdenv.hostPlatform.parsed.cpu.name}-unknown-linux-gnu";
            };
          };
        in
        import ./nix {
          inherit pkgs pkgsCrossLinux;
          lib = nixpkgs.lib;
          root = ./.;
        };
    in
    {
      packages = forAllSystems (s:
        let p = perSystem s; in {
          default = p.run;
          kernel = p.kernel;
          initramfs = p.initramfs;
          run = p.run;
        });

      apps = forAllSystems (s:
        let p = perSystem s; in {
          default = {
            type = "app";
            program = "${p.run}/bin/run-kernel";
          };
        });
    };
}
