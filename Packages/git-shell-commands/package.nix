{
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "git-shell-commands";
  version = "unstable-2022-04-05";

  src = fetchFromGitHub {
    owner = "git-utilities";
    repo = "git-shell-commands";
    rev = "d2feff33443efee822127f9216dd57bbe088ba72";
    hash = "sha256-K5yYl2qHrwfo3uLISNhaqmoN6y0Ff98I+3Egjb30jDE=";
    fetchSubmodules = true;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/git-shell-commands
    cp -r . $out/share/git-shell-commands/

    find $out/share/git-shell-commands -maxdepth 1 -type f | xargs chmod +x

    runHook postInstall
  '';
}
