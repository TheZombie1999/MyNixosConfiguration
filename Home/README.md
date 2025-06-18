## MyHomeConfiguration

## Homemanger add Channel

```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

## Install Nix

For A muli-user install run:
```bash
  sh <(curl -L https://nixos.org/nix/install) --daemon
```


## Download the repository to new host

Genertate key and add to GitHub
```bash
  ssh-keygen 
```

Get the Repository
```bash
  git clone git@github.com:TheZombie1999/MyHomeConfiguration.git
```

Move the new SSH key to the "Keys" folder and then run the  encrypt.sh script.




## Install Home-Manager




## Add second Remote 

```bash
git remote set-url --add --push origin git@github.com:TheZombie1999/MyHomeConfiguration.git
```

## Add Ssh-keys

SSH Private Keys are enrypted with gpg.
To install them on your system run the decrypt skript, 
which will prompt you for your password.
Adding a new key is as easy as running encrypt with the new key in the keys directory.


## Colors

[base16StyleDefinitions](https://github.com/chriskempson/base16/blob/main/styling.md)

- base00 - Default Background
- base01 - Lighter Background (Used for status bars, line number and folding marks)
- base02 - Selection Background
- base03 - Comments, Invisibles, Line Highlighting
- base04 - Dark Foreground (Used for status bars)
- base05 - Default Foreground, Caret, Delimiters, Operators
- base06 - Light Foreground (Not often used)
- base07 - Light Background (Not often used)
- base08 - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
- base09 - Integers, Boolean, Constants, XML Attributes, Markup Link Url
- base0A - Classes, Markup Bold, Search Text Background
- base0B - Strings, Inherited Class, Markup Code, Diff Inserted
- base0C - Support, Regular Expressions, Escape Characters, Markup Quotes
- base0D - Functions, Methods, Attribute IDs, Headings
- base0E - Keywords, Storage, Selector, Markup Italic, Diff Changed
- base0F - Deprecated, Opening/Closing Embedded Language Tags, e.g

Colors are managed with `nix-colors`:
[NixColors](https://github.com/Misterio77/nix-colors?tab=readme-ov-file)

```bash
  nix-channel --add https://github.com/misterio77/nix-colors/archive/main.tar.gz nix-colors
  nix-channel --update
```


## Backup and Restore GPG Key

To Backup your key run the following commands:

```bash
gpg --export --export-options backup --output public.gpg  
gpg --export-secret-keys --export-options backup --output private.gpg
gpg --export-ownertrust > trust.gpg
```

To Imoprt your key's run the following commands:

```bash
gpg --import public.gpg
gpg --import private.gpg
gpg --import-ownertrust trust.gpg
```

The Backup of these Keys is stored on a usb-stick *PASS*.

## Similar Prjects 

* Pickel


