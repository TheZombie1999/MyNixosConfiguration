{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "onedev";
  version = "latest";

  src = pkgs.fetchzip {
    url = "https://code.onedev.io/onedev/server/~site/onedev-latest.zip";
    sha256 = "sha256-WClDzka75FxsrZS9vGllv+JbUy6Lezi1UbwOPyuxcwY="; # ← Replace with real hash!
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  # Use Java 17 (or 21) — recommended for current OneDev
  buildInputs = [ pkgs.openjdk17 pkgs.fontconfig pkgs.dejavu_fonts pkgs.ps ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/onedev $out/bin

    # Copy the entire unpacked OneDev distribution
    cp -r . $out/share/onedev/

    # Make wrapper scripts executable
    chmod +x $out/share/onedev/bin/*.sh

    # Create a clean wrapper that forces the correct Java and working directory
    makeWrapper $out/share/onedev/bin/server.sh $out/bin/onedev \
      --set JAVA_HOME "${pkgs.openjdk17}" \
      --set PATH "${pkgs.openjdk17}/bin:${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.fontconfig pkgs.dejavu_fonts pkgs.ps ]}" \

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "OneDev - Self-hosted Git Server with CI/CD";
    homepage = "https://onedev.io/";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "onedev";
  };
}
