# SPDX-FileCopyrightText: 2025 László Vaskó <vlaci@fastmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  outputs =
    { ... }:
    {
      devenvModules.default = {
        imports = [
          ./default.nix
        ];
      };
    };
}
