# SPDX-FileCopyrightText: 2025 László Vaskó <vlaci@fastmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    optional
    ;
  cfg = config.languages.python;

  pthContent = ''import os; os.environ.pop("LD_LIBRARY_PATH", None)'';

  siteLocation =
    if cfg.venv.enable || cfg.uv.sync.enable then
      "${config.devenv.state}/venv/${config.languages.python.package.sitePackages}"
    else
      "${config.devenv.root}/.venv/${config.languages.python.package.sitePackages}";
in
{
  options.languages.python.extras.clear-ldpath.enable = mkEnableOption "clearing LD_LIBRARY_PATH in Python processes";
  config =
    mkIf
      (cfg.extras.clear-ldpath.enable && (cfg.venv.enable || cfg.poetry.enable || cfg.uv.sync.enable))
      {
        tasks."devenv:python:extras:clear-ld-library-path" = {
          exec = ''
            cat <<"EOF" > "${siteLocation}/devenv-extras.pth"
            ${pthContent}
            EOF
          '';
          after =
            optional (cfg.venv.enable && !cfg.uv.sync.enable) "devenv:python:virtualenv"
            ++ optional cfg.poetry.install.enable "devenv:python:poetry"
            ++ optional cfg.uv.sync.enable "devenv:python:uv";
          before = [ "devenv:enterShell" ];
        };
      };
}
