#!/usr/local/bin/sperl5.6.1 -U

unless ($ENV{'SERVER_NAME'}) {
  print STDERR "hello world\n";
  exit(0);
}

print "Content-type: text/html\n\n";

print "<pre>";

foreach $key (sort(keys(%ENV))) {
  $ENV{$key} =~ s/\</\&lt\;/g;
  $ENV{$key} =~ s/\>/\&gt\;/g;
  $ENV{$key} =~ s/\"/\&quot\;/g;
  print "$key:$ENV{$key}\n";
}

print "\n";

for ($index=32; $index<=255; $index++) {
  printf "%4d == &#$index; ==\n", $index; 
}
print "\n";
#
#$uid = $>;
#$gid = $);
#$gid = (split(/\s/, $gid))[0];
#
#print "UID = $uid\n";
#print "GID = $gid\n";

print "</pre>\n";


