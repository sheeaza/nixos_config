{
  internal.overlays.ov_python3_cdev = final: prev: {
    # Python for C development: the interpreter plus the packages the C
    # side's tooling needs. cshell takes it as one entry.
    python3_cdev = final.python3.withPackages (ps: [
      final.perfettoPy
      ps.pre-commit-hooks
    ]);
  };
}
