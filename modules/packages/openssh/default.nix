{
  internal.unstableOverlays.openssh-minimal = final: prev: {
    openssh-minimal = final.openssh.override {
      withFIDO = false;
      withPAM = false;
    };
  };
}
