{
  buildNpmPackage,
  fetchFromGitHub,
  pkgs,
  ...
}:

buildNpmPackage rec {
  pname = "min";
  version = "v1.35.0";

  buildInputs = with pkgs; [
    pkg-config
    electron_34
  ];

  postPatch = # bash
    ''
      cp ${./package-lock.json} package-lock.json
      cp ${./buildBin.js} scripts/buildBin.js

      substituteInPlace package.json \
        --replace-fail "buildAppImage.js" "buildBin.js"
    '';

  src = fetchFromGitHub {
    owner = "minbrowser";
    repo = pname;
    rev = "v1.35.0";
    hash = "sha256-qJ5zdtXIChoKq8Cbn9Z2Mo9MZARdHWpnUSduY6JFgcU=";
  };

  buildPhase = ''
    npm run buildAppImage
  '';

  installPhase = # bash
    ''
      env
      ls
    '';

  npmDepsHash = "sha256-c5AOxDz65ndivawCB927CrH7+Hv00ugQEy2txKS3mIs=";

  strictDeps = false;
  forceGitDeps = true;
  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  makeCacheWritable = true;
}
