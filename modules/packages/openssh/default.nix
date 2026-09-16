{
  internal.overlays.openssh-minimal = final: prev: {
    openssh-minimal = prev.openssh.override {
      withFIDO = false;
      withPAM = false;
    };
  };
}
