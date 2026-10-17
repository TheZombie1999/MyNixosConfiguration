{ writeScriptBin }:

writeScriptBin "gitlist" ''
      #! /usr/bin/env nix-shell
      #! nix-shell -i bash -p git coreutils

  		TARGET_DIR="$(pwd)"

  		[ -n "$1" ] && TARGET_DIR="$(realpath "$1")"

  		echo "Listing all subrepos of $TARGET_DIR"

  		ADD_PATH_LEN="$(realpath --relative-to="$(pwd)" "$TARGET_DIR" | wc -m)"

  		PRINT_CMD="printf \"./%-$((35 + ADD_PATH_LEN))s %-30s %s\n\" \"\$(realpath --relative-to=\"$(pwd)\" "$TARGET_DIR/\$displaypath")\" \"\$(git branch --show-current)\" \"\$(git describe --tags --dirty)\""

  		# Top Repo
  		(cd "$TARGET_DIR" && displaypath="" && eval "$PRINT_CMD")
  		# All subrepos
  		git -C "$TARGET_DIR" submodule foreach --quiet --recursive "$PRINT_CMD"
  	''
