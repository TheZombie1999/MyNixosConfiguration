{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  openjdk17,
  fontconfig,
  dejavu_fonts,
  coreutils,
  git,
  curl,
  logfile ? "/opt/onedev/logs/console.log",
  langfolder ? "/opt/onedev/lang",
  installDir ? "/opt/onedev/",
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
  buildInputs = [
    fontconfig
    coreutils
    git
    curl
    dejavu_fonts
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/

    # Copy the entire unpacked OneDev distribution
    cp -r . $out/

    substituteInPlace $out/bin/apply-db-constraints.sh \
        --replace-fail "/bin" ";/bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf" \
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""
    substituteInPlace $out/bin/backup-db.sh \
        --replace-fail "/bin" ";/bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf" \
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""
    substituteInPlace $out/bin/reset-admin-password.sh \
        --replace-fail "/bin" ";/bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf" \
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""
    substituteInPlace $out/bin/restore-db.sh \
        --replace-fail "/bin" ";/bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf"\
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""
    substituteInPlace $out/bin/server.sh \
        --replace-fail "/bin" ";/bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf" \
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""
    substituteInPlace $out/bin/upgrade.sh \
        --replace-fail "/bin" ";bin" \
        --replace-fail "WRAPPER_CMD=\"../boot/wrapper\"" "WRAPPER_CMD=$out/boot/wrapper" \
        --replace-fail "WRAPPER_CONF=\"../conf/wrapper.conf\"" "WRAPPER_CONF=$out/conf/wrapper.conf" \
        --replace-fail "PIDDIR=\".\"" "PIDDIR=\"/opt/onedev\""

    substituteInPlace $out/conf/wrapper.conf \
      --replace-fail "wrapper.logfile=../logs/console.log" "wrapper.logfile=${logfile}" \
      --replace-fail "wrapper.lang.folder=../lang" "wrapper.lang.folder=${langfolder}" \
      --replace-fail "wrapper.java.classpath.1=*.jar" "wrapper.java.classpath.1=$out/boot/*.jar" \
      --replace-fail "wrapper.java.library.path.1=." "wrapper.java.library.path.1=$out/boot/" \
      --replace-fail "wrapper.java.command=java" "wrapper.java.command=${openjdk17}/bin/java" \
      --replace-fail "wrapper.disable_console_input=TRUE" "wrapper.disable_console_input=FALSE"

    echo "wrapper.java.additional.99=-DinstallDir=${installDir}" >> $out/conf/wrapper.conf   

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
