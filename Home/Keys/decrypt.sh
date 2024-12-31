#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash gnupg ripgrep

# /home/tim/.gnupg/pubring.kbx
# ----------------------------
# pub   rsa3072 2024-01-26 [SC] [verfällt: 2026-01-25]
#       94A968B5B37C1290D43517F9670AB04423A8AB48
# uid        [ ultimativ ] Tim Schneider <tschneider.extern@varta-storage.com>
# sub   rsa3072 2024-01-26 [E] [verfällt: 2026-01-25]

privateKeys="$(\ls | rg -e '\w*.sh' -e '\w*.pub' --invert-match | rg -e '\w*.gpg')"

for key in $privateKeys ; do 
  if [ -e "${key%.*}" ]; then
    echo "File ${key%.*} allready Exists !"
  else
    gpg --output "${key%.*}" --decrypt "${key}" 
  fi
done

