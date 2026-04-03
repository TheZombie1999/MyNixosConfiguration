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

    mkdir -p $out/opt/onedev # $out/bin

    # Copy the entire unpacked OneDev distribution
    cp -r . $out/opt/onedev/

    substituteInPlace $out/opt/onedev/conf/wrapper.conf \
      --replace "wrapper.logfile=../logs/console.log" "wrapper.logfile=/home/tim/logs/onedev-console.log" \
      --replace "wrapper.lang.folder=../lang" "wrapper.lang.folder=/home/tim/lang"

    # Create a clean wrapper that forces the correct Java and working directory
    makeWrapper $out/opt/onedev/boot/wrapper-linux-x86-64 $out/opt/bin/onedev \
      --run 'cd "/opt/onedev"' \
      --set JAVA_HOME "${pkgs.openjdk17}" \
      --set PATH "${pkgs.openjdk17}/bin:${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.fontconfig pkgs.dejavu_fonts pkgs.ps ]}" \
      --set ONED_EV_DATA_DIR "/home/tim/logs" \
      --add-flags "--console /opt/onedev/wrapper.conf" \
      --add-flags " -- " \
      --add-flags "-DinstallDir=/home/tim/.local/share/myapp"


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
