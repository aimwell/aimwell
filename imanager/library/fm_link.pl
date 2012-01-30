#
# fm_link.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_link.pl,v 2.12.2.1 2006/04/25 19:48:23 rus Exp $
#
# file manager link functions
#

##############################################################################

sub filemanagerLinkCreate
{
  local($type, $fullpath, $target) = @_;

  if ($type =~ /^sym/) {
    symlink($target, $fullpath) || return(0);
  }
  else {
    link($target, $fullpath) || return(0);
  }
  return(1);
}

##############################################################################
# eof

1;

