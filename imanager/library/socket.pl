#
# socket.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/socket.pl,v 2.12.2.1 2006/04/25 19:48:25 rus Exp $
#
# open socket function
#

##############################################################################

sub socketOpen
{
  local($SOCK, $remotehost, $service) = @_;
  local($localhost, $socket_template, $tcp);
  local($localhost_address, $remotehost_address);
  local($localhost_port, $remotehost_port, $SELSOCK);

  initPlatformNetworkParameters();

  $localhost = "";
  $localhost = $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'};
  chop ($localhost = `$g_uname_path -n`) unless($localhost);

  $socket_template = 'S n a4 x8';
  $tcp = (getprotobyname('tcp'))[2];

  unless ($service =~ /^\d+$/) {
    # get service from name
    $service = (getservbyname($service, 'tcp'))[2];
  }

  $localhost_address = (gethostbyname($localhost))[4];
  $remotehost_address = (gethostbyname($remotehost))[4];

  $localhost_port = pack($socket_template, $AF_INET, 0, $localhost_address);
  $remotehost_port = pack($socket_template, $AF_INET, 
                          $service, $remotehost_address);

  socket($SOCK, $AF_INET, $SOCK_STREAM, $tcp) || 
      socketOpenError("socket(SOCK, $AF_INET, $SOCK_STREAM, $tcp) failed");

  bind($SOCK, $localhost_port) || socketOpenError("failed to bind(SOCK)");
  connect($SOCK, $remotehost_port) || 
      socketOpenError("failed to connect(SOCK)");

  $SELSOCK = select($SOCK);
  $| = 1;
  select($SELSOCK);
  return(1);
}

##############################################################################

sub socketOpenError
{
  local($errmsg) = @_;
  local($os_error);

  $os_error = $!;

  encodingIncludeStringLibrary("main");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($SOCKET_ERROR_TITLE, "help");
    htmlText($SOCKET_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      htmlUL();
      htmlText("$errmsg");
      htmlULClose();
      htmlP();
    }
    if ($os_error) {
      htmlUL();
      htmlText("$os_error");
      htmlULClose();
      htmlP();
    }
    labelCustomFooter("help");
    exit(0);
  }
  else {
    print STDERR "$errmsg\n" if ($errmsg);
    print STDERR "$os_error\n" if ($os_error);
  }
}
 
##############################################################################
# eof

1;

