#
# label.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/label.pl,v 2.12.2.2 2006/04/25 19:48:23 rus Exp $
#
# custom header and footer functions
#

##############################################################################

sub labelCustomFooter
{
  local($type) = @_;
  local($pathname, $filename, $html, $prehtml, $posthtml);
  local($curline, $authkey, $language);

  $language = encodingGetLanguagePreference();

  $type = "generic" unless ($type);
  $filename = $type . "_footer";

  if (-e "$g_labellib/$ENV{'HTTP_HOST'}/$filename") {
    $pathname = "$g_labellib/$ENV{'HTTP_HOST'}/$filename";
  }
  elsif (-e "$g_labellib/custom/$filename") {
    $pathname = "$g_labellib/custom/$filename";
  }
  else {
    $pathname = "$g_labellib/default/$filename";
  }

  $authkey = ($g_auth{'type'} && ($g_auth{'type'} eq "form")) ? 
              "AUTH=$g_auth{'KEY'}" : "";

  if (-e "$pathname") {
    open(FP, "$pathname");
    while (<FP>) {
      $curline = $_;
      $curline =~ s/__GRAPHICS_DIR__/$g_graphicslib/g;
      $curline =~ s/__ROOT_DIR__/$g_rootdir/g;
      $curline =~ s/__HTTP_HTTPS__/$urlprefix/g;
      while ($curline =~ /graphics\/lang\/__LANG_PREF__\/([A-Za-z0-9\.]*?)/) {
        if (-e "$g_graphicslib/lang/$language/$1") {
          $curline =~ s/__LANG_PREF__/$language/;
        }
        else {
          $curline =~ s/__LANG_PREF__/en/;
        }
      }
      $curline =~ s/__LANG_PREF__/$language/g;
      while ($curline =~ /__LANG_STRING__\#([a-z]*?)\#([A-Z\_]*?)\#/) {
        $strlib = $1;
        encodingIncludeStringLibrary($strlib);
        $strname = ${$2};
        $curline =~ s/__LANG_STRING__\#([a-z]*?)\#([A-Z\_]*?)\#/$strname/;
      }
      if ($authkey) {
        $curline =~ s/__AUTH_CREDENTIALS__/$authkey/g;
      }
      else {
        $curline =~ s/\?__AUTH_CREDENTIALS__//g;
        $curline =~ s/__AUTH_CREDENTIALS__//g;
      }
      $html .= $_;
    }
    close(FP);
    if ($html =~ /(.*)__NAVIGATION_MENU__(.*)/s) {
      $prehtml = $1;
      $posthtml = $2;
      print "$prehtml";
      navigationMenu(); 
      print "$posthtml";
    }
    else {
      print "$html";
    }
  }
  else {
    htmlHR("noshade", "");
    htmlP();
    navigationMenu();
    htmlP();
    htmlBodyClose();
    htmlHtmlClose();
  }
}

##############################################################################

sub labelCustomHeader
{
  local($title, $type, $javascript, $css, $bodyargs) = @_;
  local($pathname, $filename, $html, $prehtml, $posthtml, $urlprefix);
  local($curline, $authkey, $language, $strlib, $strname, $jcss);

  $language = encodingGetLanguagePreference();

  $type = "generic" unless ($type);
  $filename = $type . "_header";

  if (-e "$g_labellib/$ENV{'HTTP_HOST'}/$filename") {
    $pathname = "$g_labellib/$ENV{'HTTP_HOST'}/$filename";
  }
  elsif (-e "$g_labellib/custom/$filename") {
    $pathname = "$g_labellib/custom/$filename";
  }
  else {
    $pathname = "$g_labellib/default/$filename";
  }

  $jcss = $javascript;
  if ($css) {
    $jcss .= "\n" if ($jcss);
    $jcss .= $css;
  }

  $authkey =($g_auth{'type'} && 
             ($g_auth{'type'} eq "form")) ? "AUTH=$g_auth{'KEY'}" : "";
  $urlprefix = ($ENV{'HTTPS'} && 
                ($ENV{'HTTPS'} eq "on")) ? "https" : "http";

  if (-e "$pathname") {
    open(FP, "$pathname");
    while (<FP>) {
      $curline = $_;
      $curline =~ s/^\<body\ /\<body\ $bodyargs\ /i if ($bodyargs);
      $curline =~ s/__TITLE__/$title/g;
      if ($jcss) {
        $curline =~ s/__JAVASCRIPT__/$jcss/g;
      }
      else {
        $curline =~ s/__JAVASCRIPT__//g;
      }
      $curline =~ s/__GRAPHICS_DIR__/$g_graphicslib/g;
      $curline =~ s/__ROOT_DIR__/$g_rootdir/g;
      $curline =~ s/__HTTP_HTTPS__/$urlprefix/g;
      while ($curline =~ /graphics\/lang\/__LANG_PREF__\/([A-Za-z0-9\.]*?)/) {
        if (-e "$g_graphicslib/lang/$language/$1") {
          $curline =~ s/__LANG_PREF__/$language/;
        }
        else {
          $curline =~ s/__LANG_PREF__/en/;
        }
      }
      $curline =~ s/__LANG_PREF__/$language/g;
      while ($curline =~ /__LANG_STRING__\#([a-z]*?)\#([A-Z\_]*?)\#/) {
        $strlib = $1;
        encodingIncludeStringLibrary($strlib);
        $strname = ${$2};
        $curline =~ s/__LANG_STRING__\#([a-z]*?)\#([A-Z\_]*?)\#/$strname/;
      }
      if ($authkey) {
        $curline =~ s/__AUTH_CREDENTIALS__/$authkey/g;
      }
      else {
        $curline =~ s/\?__AUTH_CREDENTIALS__//g;
        $curline =~ s/__AUTH_CREDENTIALS__//g;
      }
      $html .= $curline;
    }
    close(FP);
    if ($html =~ /(.*)__NAVIGATION_MENU__(.*)/s) {
      $prehtml = $1;
      $posthtml = $2;
      print "$prehtml";
      navigationMenu(); 
      print "$posthtml";
    }
    else {
      print "$html";
    }
  }
  else {
    htmlHtml();
    htmlHead();
    htmlTitle($title);
    print "$javascript";
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }
}

##############################################################################
# eof

1;

