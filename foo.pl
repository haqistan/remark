##
use strict;
##
sub tab_expand {
  my $str = shift(@_);
  my $col = 0;
  my $exp = '';
  my $len = length($str);
  my $off = 0;
  while ($off < $len) {
    my $c = substr($str,$off,1);
    if ($c eq "\x9") {
      my $nspaces = $col % 8;
      if ($nspaces) {
        $nspaces = 8 - $nspaces;
        my $spaces = ' ' x $nspaces;
        $exp .= $spaces;
        $col += $nspaces;
      }
    } else {
      $exp .= $c;
      ++$col;
    }
    ++$off;
  }
  return $exp;
}
##
main: {
  my $str1 = qq{this\tor\tthat};
  my $str2 = tab_expand($str1);
  print "str1:\n$str1\n";
  print "str2:\n$str2\n";
}

##
# Local variables:
# tab-width: 2
# perl-indent-level: 2
# indent-tabs-mode: nil
# comment-column: 40
# End:
##
