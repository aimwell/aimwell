#!/usr/bin/perl
#
# minesweeper easter egg
#
# found this on the web... original author unknown
#

##############################################################################

%proximity_colors = ("1", "blue",
                     "2", "darkgreen",
                     "3", "red",
                     "4", "darkblue",
                     "5", "brown",
                     "6", "green",
                     "7", "black",
                     "8", "gray",
                     "X", "red");

%button_text = ("0", ".",
                "1", "",
                "2", "*",
                "3", "?",
                "4", " ");

##############################################################################

sub eastereggMineSweepRun
{
  print <<END;
Content-type: text/html

<html>
<head>
<title>You Found an Easter Egg! Mine Sweeper</title>
</head>
<body>
<p align="center">
<center>
<table cellpadding="4" border="1" bgcolor="#cccccc">
<tr>
<td align="left" bgcolor="#3333cc">
<font size="3" face="arial, helvetica" color="white">
&#160;<b>Mine Sweeper</b></font>
</td>
</tr>
<tr>
<td>
<font size="2" face="arial, helvetica">
END

  eastereggMineSweepNewGameButton("9", "9", "10", "Beginner");
  eastereggMineSweepNewGameButton("16", "16", "40", "Intermediate");
  eastereggMineSweepNewGameButton("16", "30", "99", "Expert");

  print <<END;
</font>
</td>
</tr>
<tr>
<td align="center">
<font size="2" face="arial, helvetica">
END

  $epoch = $g_form{'start_time'} if ($g_form{'start_time'});
  $g_form{'new_game'} = 1 if (!defined($g_form{'new_game'}));
  if ($g_form{'new_game'} eq "1") { 
    $epoch = time(); 
    $g_form{'game_over'} = 0;
    $g_form{'num_row'} = 9 if ($g_form{'num_row'} < 9);
    $g_form{'num_row'} = 24 if ($g_form{'num_row'} > 24);
    $g_form{'num_col'} = 9 if ($g_form{'num_col'} < 9);
    $g_form{'num_col'} = 30 if ($g_form{'num_col'} > 30);
    $total = $g_form{'num_row'} * $g_form{'num_col'}; 
    $g_form{'num_mines'} = 10 if ($g_form{'num_mines'} < 10);
    if ($g_form{'num_mines'} > $total) {
      $g_form{'num_mines'} = $total - 1;
    }
    $count=0; 
    while ($count < $g_form{'num_mines'}) { 
      $ii = 1 + int(rand($g_form{'num_row'})); 
      $jj = 1 + int(rand($g_form{'num_col'})); 
      if ($mine_matrix[$ii][$jj] ne "9") {
        $mine_matrix[$ii][$jj] = "9";
        $count++; 
      }
    }
  
    for ($ii=1; $ii<=$g_form{'num_row'}; $ii++) { 
      for ($jj=1; $jj<=$g_form{'num_col'};$jj++) { 
        $sweep_matrix[$ii][$jj] = "0"; 
        $count = 0;
        for ($y=-1; $y<=1; $y++) { 
          for ($x=-1; $x<=1; $x++) { 
            if ($mine_matrix[$ii+$y][$jj+$x] eq "9") { $count++; } 
          }
        }
        if ($mine_matrix[$ii][$jj] ne "9") {
          $mine_matrix[$ii][$jj]=$count; 
        }
      }
    }
  }
  else {
    $total = $g_form{'num_row'} * $g_form{'num_col'}; 
    $markedbomb = 0;
    $tms = $g_form{'map_string'};
    $jj = 1;
    $ii = 1;
    while ($tms =~ /M([\d|\+|X]+)S([\d]+)/g) {
      $mine_matrix[$ii][$jj]=$1;
      $sweep_matrix[$ii][$jj]=$2;
      if ($2==1) {
        --$total;
      }
      elsif ($2==2) {
        ++$markedbomb;
      }
      if ($1 eq "X") {
        ++$markedbomb;
      }
      $temp = "s" . ($ii * ($g_form{'num_col'}+1) + $jj); 
      if ($g_form{$temp}) {
        $myrow = $ii;
        $mycol = $jj;
        $svalue=$g_form{$temp};
      }
      $jj++;
      if ($jj == $g_form{'num_col'}+1) {
        ++$ii;
        $jj=1;
      }
    }
    $end=0; 
    if ($svalue && (! defined $g_form{'game_over'})) { 
      if ($g_form{'action'} eq "Unmark") {
        if ($svalue eq "*" ||$svalue eq "?") {
          $sweep_matrix[$myrow][$mycol]=0;
          if ($svalue eq "*") {
            $markedbomb--;
          }
        }
      }
      elsif ($g_form{'action'} eq "Mark Mine") {
        if ($svalue eq "." ||$svalue eq "?") {
          $sweep_matrix[$myrow][$mycol]=2;
          $markedbomb++;
        }
      }
      elsif ($g_form{'action'} eq "Mark ?") {
        if ($svalue eq "." ||$svalue eq "*") {
          $sweep_matrix[$myrow][$mycol]=3;
          if ($svalue eq "*") {
            $markedbomb--;
          }
        }
      }
      else {
        if ($svalue eq "."|| $svalue eq "?" ) {
          --$total;
          if ($mine_matrix[$myrow][$mycol] ne "9") { 
            $sweep_matrix[$myrow][$mycol]=1; 
            if ($mine_matrix[$myrow][$mycol] eq "0") {
              eastereggMineSweepClearArea($myrow,$mycol);
            }
          }
          else {
            $end=1; 
          }
        }
      }
    }
    if ($end == 1) { 
      $epoch = time() - $epoch;
      $g_form{'game_over'} = 1;
      for ($y=1; $y<=$g_form{'num_row'}; $y++) { 
        for ($x=1; $x<=$g_form{'num_col'}; $x++) { 
          if ($mine_matrix[$y][$x] eq "9") {
            if ($sweep_matrix[$y][$x] == 2) {
            }
            else {
              $sweep_matrix[$y][$x] = 1;
            }
          }
          else {
            if ($sweep_matrix[$y][$x] == 2) {
              $sweep_matrix[$y][$x] = 1;
              $mine_matrix[$y][$x] = "X";
            }
          }
          if ($sweep_matrix[$y][$x]==0) {
            $sweep_matrix[$y][$x] = 4;
          }
        }
      }
    }
    if (($total == $g_form{'num_mines'}) && ($end!=1) &&
        (!defined($g_form{'game_over'}))) {
      $epoch = time() - $epoch; 
      $g_form{'game_over'} = 2;
      for ($y=1; $y<=$g_form{'num_row'}; $y++) { 
        for ($x=1; $x<=$g_form{'num_col'}; $x++) { 
          if (($mine_matrix[$y][$x] eq "9") && ($sweep_matrix[$y][$x] != 2)) {
            $sweep_matrix[$y][$x]=2; 
            ++$markedbomb;
          }
        }
      }
    }
  }
  
  $num_left =  $g_form{'num_mines'} - $markedbomb;
  print <<END;
<table>
<tr>
<td valign="top">
<table>
<tr>
<td width="33%" bgcolor="black" align="center">
<font color=red><b>$num_left</b></font>
</td>
<td width="33%" bgcolor="#3333cc" align="center">
END
  if (($end == 1) || ($g_form{'game_over'})) {
    eastereggMineSweepNewGameButton($g_form{'num_row'}, $g_form{'num_col'},
                                    $g_form{'num_mines'}, ":(");
  }
  elsif (($end != 1) && ($total == $g_form{'num_mines'})) {
    eastereggMineSweepNewGameButton($g_form{'num_row'}, $g_form{'num_col'},
                                    $g_form{'num_mines'}, "B)");
  }
  else { 
    eastereggMineSweepNewGameButton($g_form{'num_row'}, $g_form{'num_col'},
                                    $g_form{'num_mines'}, ":)");
  }
  if ($g_form{'game_over'}) { 
    $time_elapsed = $epoch;
  }
  else {
    $time_elapsed =  time() - $epoch;
  }
  print <<END;
</td>
<td bgcolor="black" align="center" width="33%">
<font color=red><b>$time_elapsed</b></font>
</td>
</tr>
<tr><td colspan="3" align="center">
<form method="POST">
END
  authPrintHiddenFields();
  if ($ENV{'SCRIPT_NAME'} =~ /filemanager/) {
    formInput("type", "hidden", "name", "path", "value", $g_form{'path'});
  }
  elsif ($ENV{'SCRIPT_NAME'} =~ /mailmanager/) {
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  }
  print <<END;
<input type="hidden" name="start_time" value="$epoch">
<input type="hidden" name="num_mines" value="$g_form{'num_mines'}">
<input type="hidden" name="num_row" value="$g_form{'num_row'}">
<input type="hidden" name="num_col" value="$g_form{'num_col'}">
<input type="hidden" name="new_game" value="0">
END
  if ($g_form{'game_over'}) { 
    print "<input type=\"hidden\" name=\"game_over\" ";
    print "value=\"$g_form{'game_over'}\">\n";
  }
  print "<p>";
  print "<table bgcolor=\"#999999\">"; 
  for ($ii=1; $ii<=$g_form{'num_row'}; $ii++) {
    print "<tr bgcolor=\"#cccccc\">"; 
    for ($jj=1; $jj<=$g_form{'num_col'}; $jj++) { 
      print "<td width=\"20\" height=\"20\" ";
      print "align=\"center\" valign=\"middle\""; 
      if (($end == 1) && ($ii == $myrow) && ($jj==$mycol)) {
        print " bgcolor=\"red\"";
      } 
      print ">";
      if ($sweep_matrix[$ii][$jj]==1) { 
        if (($mine_matrix[$ii][$jj] eq "+")||($mine_matrix[$ii][$jj] eq "0")) { 
          print "&#160;"; 
        }
        else { 
          if ($mine_matrix[$ii][$jj] eq "9") { 
            print "<b>*</b>"; 
          }
          else { 
            print "<font face=\"arial, helvetica\" color=\"";
            print $proximity_colors{$mine_matrix[$ii][$jj]};
            print "\"><b>$mine_matrix[$ii][$jj]</b></font>";
          }
        }
      }
      else {
        print "<input type=submit style=\"display:inline; ";
        print "font-family:arial,helvetica; font-size=9px; ";
        print "width=20px; line-height:14px; padding:0px 0px 0px 0px;\" ";
        print "name=s".($ii*($g_form{'num_col'}+1)+$jj)." value=\"";
        print $button_text{$sweep_matrix[$ii][$jj]};
        print "\">"; 
      }
      print "</td>"; 
    }
    print "</tr>"; 
  }
  print <<END;
</table>
<br>
<font size="2" face="arial, helvetica">
On Click:
</font>
<input type="hidden" name="submit" value="ok">
<select name="action">
END
  $sel = ($g_form{'action'} eq "Sweep") ? "selected" : "";
  print "<option $sel>Sweep";
  $sel = ($g_form{'action'} eq "Mark Mine") ? "selected" : "";
  print "<option $sel>Mark Mine";
  $sel = ($g_form{'action'} eq "Mark ?") ? "selected" : "";
  print "<option $sel>Mark ?";
  $sel = ($g_form{'action'} eq "Unmark") ? "selected" : "";
  print "<option $sel>Unmark";
  print "</select>";
  print "&#160; &#160;";
  if ($g_form{'game_over'} == 1) {
    print "<font color=\"red\"><b>Kaboom!</b></font>";
  }
  elsif ($g_form{'game_over'} == 2) {
    print "<font color=\"green\"><b>All Detected!</b></font>";
  }
  $string = eastereggMineSweepBuildMapString();
  print <<END;
<input type="hidden" name="map_string" value="$string">
</td></tr></table>
</td></tr></table>
</form>
</table>
<br>
<form method="POST">
END
  authPrintHiddenFields();
  if ($ENV{'SCRIPT_NAME'} =~ /filemanager/) {
    formInput("type", "hidden", "name", "path", "value", "");
    formInput("type", "submit", "name", "return", 
              "value", $FILEMANAGER_RETURN);
  }
  elsif ($ENV{'SCRIPT_NAME'} =~ /mailmanager/) {
    formInput("type", "hidden", "name", "mbox", "value", "");
    formInput("type", "submit", "name", "return", 
              "value", $MAILMANAGER_RETURN);
  }
  print <<END;
</form>
</center>
</p>
</body>
</html>
END
}

##############################################################################

sub eastereggMineSweepClearArea 
{
  local($myrow, $mycol) = @_;
  local(@markforclear);
  local($tmpi, $tmpj);

  $mine_matrix[$myrow][$mycol] = "+";
  for ($tmpi=-1; $tmpi<=1; $tmpi++) { 
    for ($tmpj=-1; $tmpj<=1; $tmpj++) { 
      if (defined $mine_matrix[$myrow+$tmpi][$mycol+$tmpj]) {
        if ($sweep_matrix[$myrow+$tmpi][$mycol+$tmpj]!=1) {
          if ($sweep_matrix[$myrow+$tmpi][$mycol+$tmpj]!=2) {
            $sweep_matrix[$myrow+$tmpi][$mycol+$tmpj]=1;
            --$total;
          }
        }
        if ($mine_matrix[$myrow+$tmpi][$mycol+$tmpj] eq "0") {
          eastereggMineSweepClearArea($myrow+$tmpi,$mycol+$tmpj);
        }
      }
    }
  }
}

##############################################################################

sub eastereggMineSweepBuildMapString 
{
  local($ms, $xx, $yy);

  $ms = "";
  for ($xx=1; $xx<=$g_form{'num_row'}; $xx++) { 
    for ($yy=1; $yy<=$g_form{'num_col'}; $yy++) { 
      $ms .= "M" . $mine_matrix[$xx][$yy];
      $ms .= "S" . $sweep_matrix[$xx][$yy];
    } 
  } 
  return($ms);
}

##############################################################################

sub eastereggMineSweepNewGameButton 
{
  local($rows, $cols, $mines, $label) = @_;

  print <<END;
<form method="POST" style="display:inline;"><input 
  type="hidden" name="num_row" value="$rows" size="2"><input 
  type="hidden" name="num_col" value="$cols" size="2"><input 
  type="hidden" name="num_mines" value="$mines" size="2"><input 
  type="hidden" name="new_game" value="1"><input 
  type="submit" name="submit" value="$label"> 
END
  authPrintHiddenFields();
  if ($ENV{'SCRIPT_NAME'} =~ /filemanager/) {
    formInput("type", "hidden", "name", "path", "value", $g_form{'path'});
  }
  elsif ($ENV{'SCRIPT_NAME'} =~ /mailmanager/) {
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  }
  print "</form>";
}

##############################################################################
# eof

