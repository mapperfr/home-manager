{ config, lib, pkgs, ... }:

with lib;

let

  accounts = filter (a: a.getmail.enable)
    (attrValues config.accounts.email.accounts);

  renderAccountConfig = account: with account;
    let
      passCmd = concatMapStringsSep ", " (x: "'${x}'") passwordCommand;
      renderedMailboxes = concatMapStringsSep ", " (x: "'${x}'") getmail.mailboxes;
      retrieverType = if imap.tls.enable
        then "SimpleIMAPSSLRetriever"
        else "SimpleIMAPRetriever";
      destination = if getmail.destinationCommand != null
        then
        {
          destinationType = "MDA_external";
          destinationPath = getmail.destinationCommand;
        }
        else
        {
          destinationType = "Maildir";
          destinationPath = "${maildir.absPath}/";
        };
      renderGetmailBoolean = v: if v then "true" else "false";
    in ''
      # Generated by Home-Manager.
      [retriever]
      type = ${retrieverType}
      server = ${imap.host}
      ${optionalString (imap.port != null) "port = ${toString imap.port}"}
      username = ${userName}
      password_command = (${passCmd})
      mailboxes = ( ${renderedMailboxes} )

      [destination]
      type = ${destination.destinationType}
      path = ${destination.destinationPath}

      [options]
      delete = ${renderGetmailBoolean getmail.delete}
      read_all = ${renderGetmailBoolean getmail.readAll}
    '';
  getmailEnabled = length (filter (a: a.getmail.enable) accounts) > 0;
  # Watch out! This is used by the getmail.service too!
  renderConfigFilepath = a: ".getmail/getmail${if a.primary then "rc" else a.name}";

in

{
  config = mkIf getmailEnabled {
    home.file =
      foldl' (a: b: a // b) {}
      (map (a: { "${renderConfigFilepath a}".text = renderAccountConfig a; })
      accounts);
  };
}
