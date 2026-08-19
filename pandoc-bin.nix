{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "3.10.2";

  # Upstream ships fully static binaries, so there is nothing to relink; this
  # exists only because nixpkgs' `pandoc` lags several releases behind.
  sources = {
    x86_64-linux = {
      url = "https://github.com/jgm/pandoc/releases/download/${version}/pandoc-${version}-linux-amd64.tar.gz";
      hash = "sha256-x+3VNZQcSL5qNiCBp0gnKDfega4Rd3IC2cNB09gmHJo=";
    };
    aarch64-linux = {
      url = "https://github.com/jgm/pandoc/releases/download/${version}/pandoc-${version}-linux-arm64.tar.gz";
      hash = "sha256-HE1p8qCSvUfLGA5YpKq3uWNxAc7ZKCUkWMfUGn9/px0=";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pandoc-bin";
  inherit version;

  src = fetchurl (
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "pandoc-bin: no release for ${stdenvNoCC.hostPlatform.system}")
  );

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/pandoc $out/bin/pandoc
    # The same binary dispatches on argv[0], as in the upstream tarball.
    ln -s pandoc $out/bin/pandoc-server
    ln -s pandoc $out/bin/pandoc-lua
    install -Dm644 -t $out/share/man/man1 share/man/man1/*.1.gz

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/pandoc --version | grep -F "pandoc ${finalAttrs.version}"
    echo '# hi' | $out/bin/pandoc -f markdown -t html | grep -F '<h1'
    $out/bin/pandoc-lua -e 'print(pandoc.utils.stringify(pandoc.Str "ok"))' | grep -Fx ok

    runHook postInstallCheck
  '';

  meta = {
    description = "Universal markup converter, from the upstream static release";
    homepage = "https://pandoc.org";
    changelog = "https://github.com/jgm/pandoc/releases/tag/${version}";
    license = lib.licenses.gpl2Plus;
    mainProgram = "pandoc";
    platforms = lib.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
