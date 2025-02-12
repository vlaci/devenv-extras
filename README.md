<!--
SPDX-FileCopyrightText: 2025 László Vaskó <vlaci@fastmail.com>

SPDX-License-Identifier: Apache-2.0
-->

# devenv-extras

Opinionated extensions for [devenv](https://devenv.sh)

Use the provided module e.g. via `fetchurl` or using flake inputs:

```nix
{
  inputs = {
    devenv.url = "github:cachix/devenv";
    devenv-extras.url = "github:vlaci/devenv-extras";
  };
  
  outputs = inputs {
    devShells.x86_64-linux.default = devenv.lib.mkShell {
      inherit inputs;
      pkgs = nixpkgsFor.${system};
      modules = [
        ./devenv.nix
         devenv-extras.devenvModules.default
      ];
    };
  }
  ```

And use in `devenv.nix`:

```nix
{
  languages.python = {
    enable = true;
    # ...
    extras = {
      auto-patchelf.enable = true; # patch binaries in $VIRTUAL_ENV/bin
      clear-ldpath.enable = true;  # remove devenv's LD_LIBRARY_PATH environment variable
    };
}
```
