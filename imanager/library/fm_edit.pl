#
# fm_edit.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_edit.pl,v 2.12.2.4 2006/04/25 19:48:23 rus Exp $
#
# file manager edit functions
#

##############################################################################

sub filemanagerEditFileForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath, $filetype);
  local($curchar, $text, $rows, @subpaths, $filename, $wrapoption);
  local($javascript, $helpurl, $languagepref, $args, $title);

  encodingIncludeStringLibrary("filemanager");

  $languagepref = encodingGetLanguagePreference();

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
  if ($g_users{$g_auth{'login'}}->{'chroot'}) {
    $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
  }
  else {
    $displaypath = $virtualpath;
  }

  if ((-d "$fullpath") || (-l "$fullpath")) {
    # uh... oops
    $filetype = filemanagerGetFileType($fullpath);
    $filetype =~ tr/A-Z/a-z/;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__SOURCE__/$virtualpath/g;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__LCTYPE__/$filetype/g;
    filemanagerUserError($FILEMANAGER_ACTIONS_EDIT,
                         $FILEMANAGER_FILETYPE_INVALID_ERROR);
  }

  unless (-e "$fullpath") {
    filemanagerResourceNotFound("filemanagerEditFileForm
      verifying existence of \"$virtualpath\"");
  }

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  if ($g_form{'editedfile'}) {
    $text = $g_form{'editedfile'};
    if ($languagepref eq "ja") {
      $text = jcode'euc($text);
    }
    $rows = formTextAreaRows($text);
  }
  else {
    $text = "";
    $rows = formTextAreaRows();
  }

  @subpaths = split(/\//, $virtualpath);
  $filename = $subpaths[$#subpaths];

  unless ($g_form{'wrap_submit'}) {
    # default behavior is virtual word wrapping
    $g_form{'wrap_submit'} = $FILEMANAGER_ACTIONS_EDIT_WRAP_VIRTUAL;
  }
  if ($g_form{'wrap_submit'} eq $FILEMANAGER_ACTIONS_EDIT_WRAP_OFF) {
    $wrapoption = "off";
  }
  elsif ($g_form{'wrap_submit'} eq $FILEMANAGER_ACTIONS_EDIT_WRAP_PHYSICAL) {
    $wrapoption = "hard";
  }
  else {
    $wrapoption = "soft";
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  $FILEMANAGER_ACTIONS_EDIT_TEXT =~ s/__FILE__/$filename/g;
  $javascript = javascriptOpenWindow();
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_EDIT", "",
                    $javascript);
  if ($mesg) {
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
    htmlP();
  }
  htmlText($FILEMANAGER_ACTIONS_EDIT_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  if ($g_form{'wrap_submit'} ne $FILEMANAGER_ACTIONS_EDIT_WRAP_OFF) {
    formInput("type", "submit", "name", "wrap_submit", "value",
              $FILEMANAGER_ACTIONS_EDIT_WRAP_OFF);
  }
  if ($g_form{'wrap_submit'} ne $FILEMANAGER_ACTIONS_EDIT_WRAP_VIRTUAL) {
    formInput("type", "submit", "name", "wrap_submit", "value",
              $FILEMANAGER_ACTIONS_EDIT_WRAP_VIRTUAL);
  }
  if ($g_form{'wrap_submit'} ne $FILEMANAGER_ACTIONS_EDIT_WRAP_PHYSICAL) {
    formInput("type", "submit", "name", "wrap_submit", "value",
              $FILEMANAGER_ACTIONS_EDIT_WRAP_PHYSICAL);
  }
  htmlText("&#160;&#160;&#160;");
  $helpurl = (-e "help.cgi") ? "help.cgi" : "../help.cgi";
  $args = "s=wrap&language=$languagepref";
  $title = $FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT . "||" .
           $FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT_SOFT . "||" .
           $FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT_HARD;
  $title =~ s/\ +/\ /g;
  $title =~ s/\n//g;
  $title =~ s/\|/\ \n/g;
  htmlAnchor("href", "$helpurl?$args", 
             "title", $title, "onClick",
             "openWindow('$helpurl?$args', 350, 400); return false");
  htmlAnchorTextSmall($WHAT_STRING);
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  if ($g_form{'editedfile'}) {
    formTextArea($text, "name", "editedfile", "rows", $rows, "cols", 80,
                 "wrap", $wrapoption, "_FONT_", "fixed");
  }
  else {
    formTextArea("", "name", "editedfile", "rows", $rows, "cols", 80,
                 "wrap", $wrapoption, "_FONT_", "fixed",
                 "_FILENAME_", $fullpath);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_EDIT_SAVE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_EDIT_CANCEL);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerSaveEditedFile
{
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, $fsize, $fmode, $used, $homedir);

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  encodingIncludeStringLibrary("filemanager");

  if ((-d "$fullpath") || (-l "$fullpath")) {
    # uh... oops
    $filetype = filemanagerGetFileType($fullpath);
    $filetype =~ tr/A-Z/a-z/;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__SOURCE__/$virtualpath/g;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__LCTYPE__/$filetype/g;
    filemanagerUserError($FILEMANAGER_ACTIONS_EDIT,
                         $FILEMANAGER_FILETYPE_INVALID_ERROR);
  }

  unless (-e "$fullpath") {
    filemanagerResourceNotFound("filemanagerSaveEditedFile
      verifying existence of \"$virtualpath\"");
  }

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_EDIT_SAVE") {
    # save the edited file
    $g_form{'editedfile'} =~ s/\r\n/\n/g;
    $g_form{'editedfile'} =~ s/\r//g;
    if ($g_users{$g_auth{'login'}}->{'ftpquota'}) {
      # get the size of the edited file
      $fsize = length($g_form{'editedfile'});
      # get current disk usage
      $homedir = $g_users{$g_auth{'login'}}->{'home'};
      $used = filemanagerGetQuotaUsage();
      if (($fsize + $used) > 
          ($g_users{$g_auth{'login'}}->{'ftpquota'} * 1048576)) {
        # user doesn't have enough room
        $FILEMANAGER_ACTIONS_EDIT_QUOTA_ERROR =~ s/__FILE__/$virtualpath/g;
        filemanagerUserError($FILEMANAGER_ACTIONS_EDIT,
                             $FILEMANAGER_ACTIONS_EDIT_QUOTA_ERROR);
      }
    }
    if (($fullpath eq "/www/conf/httpd.conf") ||
        ($fullpath eq "/usr/local/apache/conf/httpd.conf") ||
        ($fullpath eq "/usr/local/apache2/conf/httpd.conf") ||
        ($fullpath eq "/usr/local/etc/httpd/conf/httpd.conf")) {
      # must treat this file separately since once the server detects changes
      # have been made to the file, the watcher kills child processes and
      # then restarts.  so we need to print out the html success message
      # first and then write the results to the file (and close the file)
      unless (open(FILE, ">$fullpath")) {
        filemanagerResourceError($FILEMANAGER_ACTIONS_EDIT,
                                 "open(FILE, \">$fullpath\")");
      }
      # looks like it will be successful, print out results
      htmlResponseHeader("Content-type: $g_default_content_type");
      $displaypath = $fullpath;
      $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
      labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_EDIT");
      htmlText($FILEMANAGER_ACTIONS_EDIT_SAVE_HTTPD_CONF_TEXT);
      htmlP();
      htmlUL();
      $encpath = encodingStringToURL($g_form{'path'});
      htmlAnchor("href", "filemanager.cgi?path=$encpath",
                 "title", "$CONTINUE_STRING");
      htmlAnchorText(">>> $CONTINUE_STRING <<<");
      htmlAnchorClose();
      htmlULClose();
      htmlP();
      labelCustomFooter();
      # now write out the file
      print FILE $g_form{'editedfile'};
      close(FILE);
    }
    else {
      # save the file
      unless (open(FILE, ">$fullpath")) {
        filemanagerResourceError($FILEMANAGER_ACTIONS_EDIT,
                                 "open(FILE, \">$fullpath\")");
      }
      print FILE $g_form{'editedfile'};
      close(FILE);
      # if the text file starts with the sequence '#!/', then we'll
      # assume that it should be executable 
      $fmode = (stat($fullpath))[2];
      if ((!(($fmode >> 6) & 01)) &&                # not already executable
          ($g_form{'editedfile'} =~ /^\#\!\//)) {   # begins with #!/
        # no need to check for success or failure; if it fails... oh well
        filemanagerChmod(0755, $fullpath);  
      }
      # now redirect
      $FILEMANAGER_ACTIONS_EDIT_SAVE_TEXT =~ s/\n/\ /g;
      redirectLocation("filemanager.cgi", 
                       $FILEMANAGER_ACTIONS_EDIT_SAVE_TEXT);
    }
  }
  else {
    # discard changes
    redirectLocation("filemanager.cgi", 
                     $FILEMANAGER_ACTIONS_EDIT_CANCEL_TEXT);
  }
}

##############################################################################
# eof

1;

