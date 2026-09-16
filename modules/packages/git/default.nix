{
  internal.overlays.git-minimal = final: prev: {
    gitSlim = prev.gitMinimal.override {
      curl = prev.curlMinimal.override {
        http3Support = false;
        pslSupport = false;
        scpSupport = false;
        gssSupport = false;
        idnSupport = false;
        brotliSupport = false;
        zstdSupport = false;
      };
    };
  };
}
