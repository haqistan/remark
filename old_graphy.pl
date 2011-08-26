##
##    [\/+\*\.\\] [=]  ...
##          +===========+
##          | xxxxxxxxx |
##          | xxxxxxxxx |
##          +===========+
##
$TOPSTART = '[\x2f\x2b\x2a\x2e\x5c\x7c]';
$TOPLINE  = '[\x2d=_ox]{3,}?';
##
sub old_add_node {
  my($context,$node) = @_;
  my $content = $node->{content};
  $content =~ s/\s+/ /g;
  $content =~ s/^\s+//;
  $content =~ s/\s+$//;
  $node->{content} = $content;
  my $off = $node->{off};
  my $width = $node->{width};
  my $nlines = $node->{nlines};
  my $line = $node->{line};
#  print "NODE:\n", xstring($node, 1), "\n";
  $context->{nodes} = [] unless defined $context->{nodes};
  push @{$context->{nodes}}, $node;
}
##
sub add_edge {
  my($context,$node1,$port1,$node2,$port2,$dir) = @_;
}
##
sub dump_context {
  my $context = shift(@_);
  my $nnodes = scalar @{$context->{nodes}};
  print "$nnodes NODES IN CONTEXT\n";
  my $i = 0;
  foreach my $node (@{$context->{nodes}}) {
    my $nports = $node->{nports};
    print "  NODE $i: ",$node->{content}," w/$nports ports\n";
    my $j = 0;
    foreach my $port (@{$node->{ports}}) {
      my($type,$loc) = ($port->{type},$port->{loc});
      print "    PORT $j: type $type on $loc\n";
      ++$j;
    }
    ++$i;
  }
}
##
sub old_graphy {
  my $context = shift(@_);
  my $fh = shift(@_);
  my $ul = {};
  my $last;
  my $line_no = 0;
  while (<$fh>) {
    chomp(my $input = $_);
    ++$line_no;
    $last = 0;
    my $last_len = undef;
    print qq{NEW LINE: "$input"\n};
    while ($input) {
      if (!defined($last_len)) {
        $last_len = length($input);
      } elsif (length($input) == $last_len) {
        print "STOPPING: MAKING NO PROGRESS at $last_len\n";
        last;
      } else {
        $last_len = length($input);
      }
      print qq{MATCHING $last: "$input"\n};
      if ($input =~ /^(.*?)($TOPSTART)($TOPLINE)($TOPSTART)(.*)$/) { # top/bot
        my ($a,$b,$c,$d,$e) = ($1,$2,$3,$4,$5);
        my $off = length($a);
        my $loc = $off + $last;
        my $width = length($b) + length($c) + length($d);
#D+     print qq{MATCH: off=$off loc=$loc width=$width b="$b" c="$c" d="$d"\n};
        my $node;
        my $is_top = 0;
        if ($c) {
          if (!defined($ul->{$loc})) {
            $node =
              {
               line => $line_no,
               off => $off,
               width => $width,
               beg => $b,
               bar => $c,
               end => $d,
               content => '',
               nlines => 0,
               nports => 0,
               ports => [],
              };
            $ul->{$loc} = [ $node ];
            $is_top = 1;
          } else {
            my $match_at = -1;
            my $match = undef;
            my $i = 0;
            foreach my $x (@{$ul->{$loc}}) {
              if ($x->{width} == $width) {
                $match_at = $i;
                $match = $x;
                last;
              }
              ++$i;
            }
#D+            print "NO MATCH FOR NODE loc=$loc width=$width: ",
#D+              xstring($ul->{$loc}),"\n" unless defined $match;
            if (defined($match)) {
              $node = $match;
              if ($match->{nlines} > 0) {
                my @left = ();
                $i = 0;
                foreach my $y (@{$ul->{$loc}}) {
                  push @left, $y unless $i == $match_at;
                  ++$i;
                }
                if (!scalar(@left)) {
                  delete $ul->{$loc};
                } else {
                  $ul->{$loc} = \@left;
                }
              } else {
                print "DITCHING EMPTY NODE: ",xstring($match),"\n";
              }
            }
          }
#D+          print qq{SCANNING NODE FOR PORTS: },xstring($node),"\n";
          ## now deal with ports
          my $bar = $c;
#D+          print
#D+            qq{SCANNING BAR ($is_top): "$bar"\nNODE IS: },xstring($node),"\n";
          while ($bar) {
            if ($bar =~ /^([\x2d=]+)([ox:\x2e\x2a])([^ox:\x2e\x2a].*)$/) {
              my($a,$b,$c) = ($1,$2,$3);
#D+              print qq{BAR SCAN: a="$a" b="$b" c="$c"\n};
              my $port =
                {
                 type => $b,
                 number => $node->{nports},
                 loc => $is_top? 'top': 'bot',
                };
              ++$node->{nports};
              push @{$node->{ports}}, $port;
              $bar = $c;
            } else {
              $bar = undef;
            }
          }
          add_node($context, $node) if ($node && !$is_top);
        }
        $input = $e;
        $last = $loc + $width;
#D+        print qq{AFTER MATCH: last=$last input="$input"\n};
      } elsif ($input =~ /^([^|]+)([|x])(.+?)([|x])(.*)$/) { # guts of a node
        my($a,$b,$c,$d,$e) = ($1,$3,$5,$2,$4);
        my $off = length($a);
        my $loc = $off + $last;
        my $width = length($b);
        my $node;
        print
          qq{MATCH2: off=$off loc=$loc width=$width }.
          qq{a="$a" b="$b" c="$c" d="$d" e="$e"\n};
        if ($b) {
          $width += 2;
          if (defined($ul->{$loc})) {
            foreach my $x (@{$ul->{$loc}}) {
              if ($x->{width} == $width) {
                $x->{content} .= qq{ $b };
                ++$x->{nlines};
                $node = $x;
                last;
              }
            }
          }
        }
        if ($node) {
          if ($d =~ /[x\x2a]/) {
            my $port =
              {
               type => 'x',
               number => $node->{nports},
               loc => 'lhs',
              };
            ++$node->{nports};
            push @{$node->{ports}}, $port;
          }
          if ($e =~ /[x\x2a]/) {
            my $port =
              {
               type => 'x',
               number => $node->{nports},
               loc => 'rhs',
              };
            ++$node->{nports};
            push @{$node->{ports}}, $port;
          }
        }
        $input = $c;
        $last = $loc + $width;
#D        print qq{AFTER MATCH2: last=$last input="$input"\n};
      }
    }
  }
  ##
  foreach my $key (sort ascending (keys %$ul)) {
    print "key leftover: $key => ",xstring($ul->{$key}),"\n";
  }
}
