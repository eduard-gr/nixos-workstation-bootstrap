{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (python314.withPackages (ps: with ps; [
      pandas

      # pandas-ta was removed from nixpkgs unstable ("abandoned upstream");
      # vendored here from the last nixpkgs 26.05 derivation.
      (ps.buildPythonPackage rec {
        pname = "pandas-ta";
        version = "0.3.14b";
        pyproject = true;

        src = pkgs.fetchurl {
          # pandas-ta.dev no longer resolves; the Wayback Machine copy is
          # byte-identical (same sha256).
          urls = [
            "https://web.archive.org/web/2025id_/https://www.pandas-ta.dev/assets/zip/pandas_ta-${version}.tar.gz"
            "https://www.pandas-ta.dev/assets/zip/pandas_ta-${version}.tar.gz"
          ];
          hash = "sha256-D6Na7IMdKBXqMLhxaIqNIKdrKIp74tJswAw1zYwJqZM=";
        };

        postPatch = ''
          substituteInPlace pandas_ta/momentum/squeeze_pro.py \
            --replace-fail "import NaN" "import nan"

          # setuptools in nixpkgs unstable no longer ships pkg_resources;
          # replace the pkg_resources-based version lookup with a literal.
          sed -i '/^from pkg_resources import/,/^version = __version__ = _dist.version$/c\version = __version__ = "${version}0"' \
            pandas_ta/__init__.py
        '';

        build-system = [ ps.setuptools ];

        dependencies = with ps; [
          numpy
          pandas
          python-dateutil
          pytz
          setuptools
          six
        ];

        doCheck = false;
        pythonImportsCheck = [ "pandas_ta" ];
      })

      scipy
      matplotlib
      numpy
      plotly
      sqlalchemy
      clickhouse-connect

      sklearn-compat

    ]))
  ];
}
