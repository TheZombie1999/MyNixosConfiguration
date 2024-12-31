
{ config, pkgs, ... }:
{
  
  programs.broot = {
    enableBashIntegration	= true;
    enable = true;
  };

  # programs.broot.settings.modal	Whether to enable modal (vim) mode.	boolean
  # programs.broot.settings.skin	Color configuration. Complete list of keys (expected to change before the v1 of broot): * `char_match` * `code` * `directory` * `exe` * `file` * `file_error` * `flag_label` * `flag_value` * `input` * `link` * `permissions` * `selected_line` * `size_bar_full` * `size_bar_void` * `size_text` * `spinner` * `status_error` * `status_normal` * `table_border` * `tree` * `unlisted` Add `_fg` for a foreground color and `_bg` for a background color.	attribute set of string
  # programs.broot.settings.verbs	Define new verbs. For more information, see [Verb Definition Attributes](https://dystroy.org/broot/documentation/configuration/#verb-definition-attributes) in the broot documentation. The possible attributes are: `invocation` (optional) : how the verb is called by the user, with placeholders for arguments `execution` (mandatory) : how the verb is executed `key` (optional) : a keyboard key triggering execution `shortcut` (optional) : an alternate way to call the verb (without the arguments part) `leave_broot` (optional) : whether to quit broot on execution (default: `true`) `from_shell` (optional) : whether the verb must be executed from the parent shell (default: `false`)	list of attribute set of (boolean or string)
  # programs.broot.settings	Verbatim config entries	TOML value

}
