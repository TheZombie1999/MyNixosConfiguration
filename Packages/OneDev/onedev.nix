{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  openjdk17,
  fontconfig,
  dejavu_fonts,
  coreutils,
  ...
}:

stdenv.mkDerivation {
  pname = "onedev";
  version = "latest";

  src = fetchzip {
    url = "https://code.onedev.io/onedev/server/~site/onedev-latest.zip";
    sha256 = "sha256-WClDzka75FxsrZS9vGllv+JbUy6Lezi1UbwOPyuxcwY="; # ← Replace with real hash!
  };

  nativeBuildInputs = [ makeWrapper ];

  # Use Java 17 (or 21) — recommended for current OneDev
  buildInputs = [
    openjdk17
    fontconfig
    dejavu_fonts
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/onedev

    # Copy the entire unpacked OneDev distribution
    cp -r . $out/opt/onedev/

    substituteInPlace $out/opt/onedev/conf/wrapper.conf \
      --replace-fail "wrapper.logfile=../logs/console.log" "wrapper.logfile=/opt/onedev/logs/console.log" \
      --replace-fail "wrapper.lang.folder=../lang" "wrapper.lang.folder=/opt/onedev/lang" \
      --replace-fail "wrapper.java.classpath.1=*.jar" "wrapper.java.classpath.1=$out/opt/onedev/boot/*.jar" \
      --replace-fail "wrapper.java.library.path.1=." "wrapper.java.library.path.1=$out/opt/onedev/boot/" 
      # --replace-fail "# wrapper.debug=TRUE" "wrapper.debug=TRUE"

    substituteInPlace $out/opt/onedev/conf/hibernate.properties \
      --replace-fail "''${installDir}" "/opt/onedev"

    echo "wrapper.java.additional.99=-DinstallDir=/opt/onedev/" >> $out/opt/onedev/conf/wrapper.conf   

    makeWrapper $out/opt/onedev/boot/wrapper-linux-x86-64 $out/bin/onedev \
      --set JAVA_HOME "${openjdk17}" \
      --set PATH "${openjdk17}/bin:${
        lib.makeBinPath [
          coreutils
          fontconfig
          dejavu_fonts
        ]
      }" \
      --add-flags "--console $out/opt/onedev/conf/wrapper.conf"

    runHook postInstall
  '';

  meta = with lib; {
    description = "OneDev - Self-hosted Git Server with CI/CD";
    homepage = "https://onedev.io/";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "onedev";
  };
}
