# SPDX-FileCopyrightText: 2025 László Vaskó <vlaci@fastmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    makeLibraryPath
    mkEnableOption
    mkIf
    optional
    optionalString
    replaceStrings
    ;
  cfg = config.languages.python;
  # from devenv/src/modules/languages/python.nix
  libraries = makeLibraryPath (
    cfg.libraries
    ++ (optional cfg.manylinux.enable pkgs.pythonManylinuxPackages.manylinux2014Package)
    ++ [ pkgs.stdenv.cc.cc.lib ]
  );
  auto-patchelf =
    venv:
    let
      drv = pkgs.buildEnv {
        name = "patchelf";
        paths = [
          pkgs.patchelf
          pkgs.auto-patchelf
        ];
      };
      librariesArgs = replaceStrings [ ":" ] [ " " ] libraries;
    in
    ''
       exec 19>/tmp/trace
       export BASH_XTRACEFD=19
       set -x

      _devenv_venv_checksum() {
        ${pkgs.nix}/bin/nix-hash --type sha256 "${venv}"/bin
      }

      _devenv_patchelf() {
        local VENV_CHECKSUM="$(_devenv_venv_checksum)"
        local VENV_CHECKSUM_FILE="${venv}/venv.checksum"
        local EXPECTED_VENV_CHECKSUM=

        if [[ -f "$VENV_CHECKSUM_FILE" ]]; then
          EXPECTED_VENV_CHECKSUM=$(<"$VENV_CHECKSUM_FILE")
        fi

        if [[ "$(_devenv_venv_checksum)" != "$EXPECTED_VENV_CHECKSUM" ]]; then
          ${drv}/bin/auto-patchelf \
            --paths ${venv}/bin \
            --libs ${librariesArgs} \
            --runtime-dependencies \
            --append-rpaths \
            --ignore-missing \
            --extra-args

          # patchelf may change the checksum
          echo "$(_devenv_venv_checksum)" > "$VENV_CHECKSUM_FILE"
        fi
      }
      _devenv_patchelf
    '';

in
{
  options.languages.python.extras.auto-patchelf.enable = mkEnableOption "patching binaries";

  config = mkIf cfg.extras.auto-patchelf.enable {
    tasks."devenv:python:extras:auto-patchelf" = {
      exec =
        optionalString cfg.poetry.install.enable ''
          ${auto-patchelf "${config.devenv.root}/.venv"} 
        ''
        + optionalString (cfg.venv.enable || cfg.uv.sync.enable) ''
          ${auto-patchelf "${config.devenv.state}/venv"} 
        '';
      after =
        optional (cfg.venv.enable && !cfg.uv.sync.enable) "devenv:python:virtualenv"
        ++ optional cfg.poetry.install.enable "devenv:python:poetry"
        ++ optional cfg.uv.sync.enable "devenv:python:uv";
      before = [ "devenv:enterShell" ];
    };
  };
}
