let
  ov_perfetto = final: prev: {
    # Perfetto's Python package, from PyPI. Not in nixpkgs. The generated
    # protobuf classes it ships need the protobuf runtime, nothing else
    # is required.
    perfettoPy = final.python3Packages.buildPythonPackage rec {
      pname = "perfetto";
      version = "0.58.2";
      format = "wheel";
      src = final.python3Packages.fetchPypi {
        inherit pname version format;
        dist = "py3";
        python = "py3";
        hash = "sha256-Ak032z4ZOKAkcxEzfa9BnHIEr3V/swPNwdykb6jYPP4=";
      };
      dependencies = [ final.python3Packages.protobuf ];
      doCheck = false;
      pythonImportsCheck = [ "perfetto.protos.perfetto.trace.perfetto_trace_pb2" ];
    };
  };
in
{
  internal.pkgOverlays = [ ov_perfetto ];
}
