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
          url = "https://www.pandas-ta.dev/assets/zip/pandas_ta-${version}.tar.gz";
          hash = "sha256-D6Na7IMdKBXqMLhxaIqNIKdrKIp74tJswAw1zYwJqZM=";
        };

        postPatch = ''
          substituteInPlace pandas_ta/momentum/squeeze_pro.py \
            --replace-fail "import NaN" "import nan"
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
