#
# encoding.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/encoding.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# language loading and encoding functions
#

##############################################################################

sub encodingGetLanguagePreference
{
  local($language, @acls, $acl);

  # okay... figure out what language library we should use
  #   1) first check language in the form data
  #   2) next check the user's language preference
  #   3) next check the browser's language setting
  #   4) if all else fails, set to g_defaultlanguage (see init.pl)

  $language = $g_defaultlanguage;  # initialize value: case (4)

  if ($g_form{'language'}) {
    # case (1)
    $language = $g_form{'language'};
  }
  elsif (defined($g_prefs{'general__language'}) &&
         ($g_prefs{'general__language'} ne "default")) {
    # case (2)
    $language = $g_prefs{'general__language'};
  }
  elsif ($ENV{'HTTP_ACCEPT_LANGUAGE'}) {
    # case (3)
    # format of HTTP_ACCEPT_LANGUAGE: fr, en, pt-br, ...
    $acl = $ENV{'HTTP_ACCEPT_LANGUAGE'};
    $acl =~ tr/A-Z/a-z/;        # lower case-ize
    $acl =~ s/\s//g;            # eliminate stuff (e.g. spaces)
    @acls = split(/\,/, $acl);  # split around comma
    foreach $acl (@acls) {
      $acl =~ s/;(.*)$//;
      if (-e "$g_stringlib/$acl/") {
        $language = $acl;
        last;
      }
    }
  }
  return($language);
}
  
##############################################################################

sub encodingIncludeStringLibrary
{
  local($library) = @_;
  local($language, $filename);

  # first, always include the english library.  this will ensure that at the
  # very least, the english defintion of the library strings exists.  later,
  # when the library of the preferred language is loaded, the strings will be
  # redefined if they exist -- i.e. new strings which quite haven't been
  # translated in the non-english string libraries will at least be defined
  # in english
  $filename = "$g_stringlib/en/$library";
  delete($INC{$filename});
  require($filename);

  # now look for the string library in the user's language of choice
  $language = encodingGetLanguagePreference();
  $filename = "$g_stringlib/$language/$library";
  unless (-e "$filename") {
    # fall back to english
    $filename = "$g_stringlib/en/$library";
  }
  delete($INC{$filename});
  require($filename);
}

##############################################################################

sub encodingSetDefaultContentType
{
  local($language);

  $language = encodingGetLanguagePreference();

  if ($language eq "ja") {
    $g_default_content_type = "text/html; charset=EUC-JP";
    # load the ja encoding/decoding libraries
    require("$g_includelib/lang/ja/jcode.pl");
    require("$g_includelib/lang/ja/mimer.pl");
    require("$g_includelib/lang/ja/mimew.pl");
  }
  else {
    $g_default_content_type = "text/html; charset=iso-8859-1";
  }
}

##############################################################################

sub encodingStringToURL
{
  local($string) = @_;
  local($encodedstring);

  $encodedstring = "";
  if ($string) {
    $encodedstring = $string;
    $encodedstring =~ s/([^a-zA-Z0-9_\-.\ ])/uc sprintf("%%%02x",ord($1))/eg;
    $encodedstring =~ s/\ /\+/g;
  }
  return($encodedstring);
}

##############################################################################
# eof

1;

