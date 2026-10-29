{
  internal.unstableOverlays.tig = final: prev: {
    tig = prev.tig.override { git = final.gitSlim; };
  };

  internal.unstableOverlays.git-minimal = final: prev: {
    gitSlim = final.gitMinimal.override {
      curl = final.curlMinimal.override {
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
