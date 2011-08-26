#!/usr/bin/perl
#
# filename - brief description
#
# (C) 1997-2003 by attila <attila@stalphonsos.com>.  all rights reserved.
#
# Time-stamp: <2003-09-27 21:31:34 EDT attila@stalphonsos.com>
# $Id$
#
# author: attila <attila@stalphonsos.com>
#
# Description:
#
# See description at EOF
#
use strict;
use vars qw($ORIGINAL_SCRIPT $P $VERSION $VERBOSE $OPTS $USAGE $DESCR $AUTHOR
            $COPYRIGHT $ARGS_DESC $LOG_STDERR $LOG_FILE $LOG_FP $LOG_TSTAMP_FMT
            $DEFAULTS $TOPSTART $TOPLINE);
BEGIN {
  $ORIGINAL_SCRIPT = $0;
  my(@P) = split("/", $0);
  $P = pop(@P);
  my $dir = join('/', @P);
  unshift(@INC, $dir);
  ## If we're being run out of a bin/ directory and there is ../lib, then
  ## add it to @INC
  if ($P[$#P] eq 'bin') {
    my @tmp = @P;
    pop(@tmp);
    my $tmp = join("/",@tmp)."/lib";
    unshift(@INC, $tmp) if (-d $tmp);
    $tmp .= "/perl";
    unshift(@INC, $tmp) if (-d $tmp);
  }
  my $ndir = "$dir/../lib/perl5/site_perl";
  unshift(@INC, $ndir) if (-d $ndir);
}
##
use POSIX;
use Getopt::Std;
use WebApp::Utils qw/:all/;
##
$DEFAULTS =
  {
  };
$VERSION = '0.1.0';
$DESCR = '<< describe the program >>';
$AUTHOR = 'attila <attila@stalphonsos.com>';
$VERBOSE = 0;
$OPTS = 'hvV:';
$COPYRIGHT=
  '(C) 1997-2003 by attila <attila@stalphonsos.com>. all rights reserved.';
$ARGS_DESC = "args...";
$LOG_STDERR = 1;
$LOG_FILE = undef;
$LOG_FP = undef;
$LOG_TSTAMP_FMT = '%Y-%m-%d %H:%M:%S';
$USAGE = <<__UsAGe__;
  options:
           -h    print this message and exit
           -v    be verbose
           -V x  set verbosity to x (-v is the same as -V 1)
  args...
__UsAGe__
##
sub opts_str {
  my $str = shift(@_);
  my $dostr = "";
  my $dvstr = "";
  my @opts = split("", $str);
  my $dvcol = 0;
  my $maxdv = 30;
  while (my $o = shift(@opts)) {
    if ($opts[0] eq ':') {
      shift(@opts);
      if ($dvcol > $maxdv) {
        $dvstr .= ("\n" . (" " x (11 + length($P))));
        $dvcol = 11 + length($P);
        $maxdv = 65;
      }
      $dvstr .= " " if length($dvstr);
      $dvstr .= "[-$o x]";
      $dvcol += 7;
    } else {
      $dostr .= "[-" unless length($dostr);
      $dostr .= $o;
    }
  }
  $dostr .= "]" if length($dostr);
  my $dstr = $dostr;
  $dstr .= " " if length($dstr);
  $dstr .= $dvstr;
  return $dstr;
}
##
sub usage_section {
  my $fh = shift(@_);
  my $regexp = shift(@_);
  my $title = shift(@_) || $P;
  my $hdr_fmt = shift(@_);
  my $in_sect = 0;
  while (<$fh>) {
    next unless ($in_sect || /^=head1\s+$regexp/);
    if (/^=head1\s+$regexp/) {
      $in_sect = 1;
      print STDERR "\n  ","-" x 20, "[ $title ]", "-" x 20,"\n\n";
      print STDERR sprintf($hdr_fmt, @_) if $hdr_fmt;
      next;
    } elsif ($in_sect && /^=cut/) {
      last;
    } elsif ($in_sect) {
      print STDERR $_;
    }
  }
}
##
sub usage {
  my $msg = shift(@_);
  print STDERR sprintf("%9s: %s\n", "ERROR", $msg) if $msg;
  print STDERR sprintf("%9s: %s\n", $P, $DESCR);
  print STDERR sprintf("%9s: %s\n", "version", $VERSION);
  print STDERR sprintf("%9s: %s\n", "copyright", $COPYRIGHT);
  print STDERR sprintf("%9s: %s\n", "author", $AUTHOR);
  print STDERR sprintf("%9s: %s %s %s\n", "usage", $P, opts_str($OPTS),
                       $ARGS_DESC);
  print $USAGE;
  if (scalar(@_)) {
    my $nope = 0;
    open(ME, "<$0") || ($nope=1);
    unless ($nope) {
      usage_section(\*ME, 'DESCRIPTION', '  DESCRIPTION  ');
      usage_section(\*ME, 'VERSION',     'VERSION HISTORY',
                    "  %-7s   %-9s   %-7s %s\n", "VERS", "WHEN",
                    "WHO", "WHAT");
      close(ME);
    }
  }
  exit(defined($msg));
}
##
sub ts {
  my $fmt = $LOG_TSTAMP_FMT || "%Y-%m-%d %H:%M:%S";
  return POSIX::strftime($fmt, localtime(time));
}
##
sub log_msg {
  my $lvl = shift(@_);
  return unless $VERBOSE >= $lvl;
  my $logmsg = "$P: " . ts() . " [$lvl] @_\n";
  print STDERR $logmsg if $LOG_STDERR;
  if ($LOG_FILE && !$LOG_FP) {
    $LOG_FP = new IO::File(">> $LOG_FILE")
      or die "$P: could not create log file $LOG_FILE: $!\n";
  }
  print $LOG_FP $logmsg if $LOG_FP;
}
##
sub ascending { $a <=> $b }
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
sub new_graphy {
  my $name = shift(@_);
  my $context =
    {
      name => $name,
      nodes_at => {},
      nodes => [],
      edges => [],
      ports => {},
      errors => [],
      input_source => '',
      raw_chars => [],
    };
  return $context;
}
##
sub graphy_error {
  my($context,$line_no,$msg) = @_;
  push @{$context->{errors}}, "$line_no:$msg";
}
##
sub graphy_record_char {
  my($context,$x,$y,$c) = @_;
}
##
sub node_bar {
  my($context,$col,$line_no,$width) = @_;
  my $nodes = $context->{nodes_at}->{$col};
  if (!defined($nodes)) {
    $nodes =
        [
         {
           x => $col,
           y => $line_no,
           w => $width,
           h => 0,
           ports => [],
           label => '',
           finished => 0,
         }
        ];
    $context->{nodes_at}->{$col} = $nodes;
  } else {
    my @new_nodes = ();
    foreach my $node (@$nodes) {
      if (!$node->{finished} && ($node->{y} < $line_no)) {
        $node->{finished} = 1;
        $node->{h} = $line_no - $node->{y};
        push @{$context->{nodes}}, $node;
      } else {
        push @new_nodes, $node;
      }
    }
    if (!scalar(@new_nodes)) {
      delete $context->{nodes_at}->{$col};
    } else {
      $context->{nodes_at}->{$col} = \@new_nodes;
    }
  }
}
##
sub node_port {
  my($context,$port,$start_col,$line_no,$loc) = @_;
  my $nodes = $context->{nodes_at}->{$start_col};
  if (defined($nodes)) {
    foreach my $node (@$nodes) {
      if ($node->{y} < $line_no) {
        my @newports = ();
        my $newport = { port => $port, loc => $loc, 'y' => $line_no };
        my $pushed = 0;
        foreach my $p (@{$node->{ports}}) {
          if ($p->{port} < $port) {
            push @newports, $p;
          } elsif ($p->{port} == $port) {
            my $x = $node->{x};
            my $y = $line_no;
            graphy_error($context,$line_no,
                         qq{duplicate port $port at $x,$y ($loc)});
            return;
          } else {
            push @newports, $newport unless $pushed;
            push @newports, $p;
            $pushed = 1;
          }
        }
        $node->{ports} = \@newports;
        if (!defined($context->{ports}->{$port})) {
          $context->{ports}->{$port} =
            {
              src => $node, srcport => $newport,
              dst => undef, dstport => undef
            };
        } elsif (defined($context->{ports}->{$port}->{dst})) {
          graphy_error($context,$line_no,qq{duplicated port $port?});
        } else {
          $context->{ports}->{$port}->{dst} = $node;
          $context->{ports}->{$port}->{dstport} = $newport;
        }
        last;
      }
    }
  } else {
    print qq{failed port $port at $start_col,$line_no $loc\n};
  }
}
##
sub add_guts {
  my($context,$start_col,$line_no,$guts) = @_;
  $guts =~ s/^\s+//;
  $guts =~ s/\s+$//;
  return unless length($guts);
  my $nodes = $context->{nodes_at}->{$start_col};
  if (defined($nodes)) {
    foreach my $node (@$nodes) {
      if ($node->{y} < $line_no) {
        $node->{label} .= ' ' if length($node->{label});
        $node->{label} .= $guts;
        last;
      }
    }
  }
}
##
sub indicate {
  return unless $VERBOSE;
  my $at = shift(@_);
  my $what = "@_";
  print ' ' x ($at+3);
  print "^ $what\n";
}
##
sub graphy_examine_line {
  my($context,$line,$line_no) = @_;
  my $tabline = tab_expand($line);
  my $col = 0;
  my $ncols = length($tabline);
  my $state = 'none';
  my $inside = 0;
  my $start_col = undef;
  my $prev_c = undef;
  my $next_c = undef;
  my $guts = '';
  printf "%02d:%s\n", $line_no, $tabline if $VERBOSE;
  while ($col < $ncols) {
    my $c = substr($tabline,$col,1);
    $next_c = substr($tabline,$col+1,1);
    my $already = defined($context->{nodes_at}->{$col})? 1: 0;
    if ($c eq '#') {
      if ($state eq 'none') {
        $state = 'hash';
        $start_col = $col;
        indicate($col,qq{hash at $col});
      } elsif ($state eq 'hash') {
        $state = 'bar';
        indicate($col,qq{bar from $start_col});
      } elsif ($state eq 'guts') {
        indicate($col,qq{end of guts from $start_col ($guts)});
        add_guts($context,$start_col,$line_no,$guts);
        $guts = '';
        $state = 'none';
        $inside = 0;
        $start_col = undef;
      }
    } elsif ($state eq 'hash') {
      if ($c =~ /[0-9]/) {
        $state = 'bar';
        indicate($col,qq{bar port $c from $start_col});
        node_port($context,$c,$start_col,$line_no,$already? 'bot': 'top');
      } elsif ($c eq ' ') {
        $inside = !$inside;
        if (!$inside) {
          indicate($col,qq{guts from $start_col ($guts)});
          add_guts($context,$start_col,$line_no,$guts);
          $guts = '';
          $state = 'none';
        } else {
          indicate($col,qq{start guts});
          $state = 'guts';
        }
      } elsif ($c ne '#') {
        indicate($col,qq{bar end from $start_col ($guts)});
        add_guts($context,$start_col,$line_no,$guts);
        $guts = '';
        $state = 'none';
      } else {
        indicate($col,qq{hash to bar});
        $state = 'bar';
      }
    } elsif ($state eq 'bar') {
      if ($c =~ /[0-9]/) {
        indicate($col,qq{port $c from $start_col});
        node_port($context,$c,$start_col,$line_no,$already? 'bot': 'top');
      } elsif ($c ne '#') {
        $state = 'none';
        indicate($col,qq{end of bar from $start_col});
        node_bar($context,$start_col,$line_no,$col - $start_col);
        $start_col = undef;
      }
    } elsif ($state eq 'guts') {
      if (($c =~ /[0-9]/) && ($prev_c eq ' ') && ($next_c =~ /[\.<>]/)) {
        indicate($col,qq{port $c in guts from $start_col ($guts)});
        node_port($context,$c,$start_col,$line_no,'rhs');
        add_guts($context,$start_col,$line_no,$guts);
        $guts = '';
        $state = 'none';
        $inside = 0;
        $start_col = undef;
      } elsif ($c eq '#') {
        indicate($col,qq{end of guts from $start_col ($guts)});
        add_guts($context,$start_col,$line_no,$guts);
        $guts = '';
        $state = 'none';
        $inside = 0;
        $start_col = undef;
      } else {
        $guts .= $c;
      }
    } elsif ($state eq 'none') {
      if (($c =~ /[0-9]/) && ($prev_c =~ /[\.<>]/) && ($next_c eq ' ') && $already) {
        indicate($col,qq{start of more guts and port $c at $col});
        $state = 'guts';
        $inside = 1;
        $start_col = $col;
        node_port($context,$c,$start_col,$line_no,'lhs');
      }
    } else {
      ## nothing
    }
    graphy_record_char($context,$line_no,$col,$c);
    ++$col;
    $prev_c = $c;
  }
}
##
sub graphy {
  my($metactx,$stream,$line_no) = @_;
  $line_no ||= 0;
  my @list = ();
  my $g = undef;
  my $this_line_no = undef;
  while (<$stream>) {
    chomp;
    if (!defined($g) && /^\s+=\[\s+(graph|figure|illustration)(:|\s+\d+:)\s+(\S.*)\]=/) {
      my($what,$num,$name) = ($1,$2);
      my $countvar = $what.'_count';
      if ($num eq ':') {
        $num = ++$metactx->{$countvar};
      } elsif ($num =~ /^\s+(\d+):/) {
        $num = $1;
        if ($metactx->{$countvar} >= $num) {
          ctx_error($metactx,$line_no,qq{$what $num already exists?});
        } else {
          $metactx->{$countvar} = $num;
        }
      } else {
        $num = ++$metactx->{$countvar};
      }
      $name =~ s/^\s+//;
      $name =~ s/\s+$//;
      print qq{starting new $what: $name at $line_no\n};
      $g = new_graphy($name,$metactx);
      $this_line_no = 0;
    } elsif (defined($g)) {
      if (/^\s+=\[\s+graph:\send\s+\]=/) {
        print qq{ending graph $g->{name} at $line_no\n};
        push @list, $g;
        $g = undef;
        $this_line_no = undef;
      } else {
        graphy_examine_line($g,$_,$this_line_no);
        ++$this_line_no;
      }
    } # else nothing
    ++$line_no;
  }
  push @list, $g if defined $g;
  return @list;
}
##
sub dump_graphy {
  my($context) = @_;
  my $nnodes = scalar(@{$context->{nodes}});
  my $nerrors = scalar(@{$context->{errors}});
  my $nunder = scalar(keys %{$context->{nodes_at}});
  my $nports = scalar(keys %{$context->{ports}});
  my $name = $context->{name};
  print qq{graphy "$name": $nnodes nodes, $nerrors errors, $nports ports, $nunder under constr.\n};
  foreach my $err (@{$context->{errors}}) {
    print "  error: $err\n";
  }
  foreach my $node (@{$context->{nodes}}) {
    my($x,$y,$w,$h,$label) =
      ($node->{x},$node->{y},$node->{w},$node->{h},$node->{label});
    print "  node: $x,$y + $w x $h: $label\n";
    foreach my $port (@{$node->{ports}}) {
      my($loc,$y) = ($port->{loc},$port->{y});
      print "    port: $y at $loc\n";
    }
  }
  foreach my $at (sort ascending (keys %{$context->{nodes_at}})) {
    print "  nodes under construction at $at:\n";
    foreach my $node (@{$context->{nodes_at}->{$at}}) {
      my($x,$y,$w,$h,$label) =
        ($node->{x},$node->{y},$node->{w},$node->{h},$node->{label});
      print "    node: $x,$y + $w x $h: $label\n";
    }
  }
  foreach my $p (sort ascending (keys %{$context->{ports}})) {
    my $port = $context->{ports}->{$p};
    my($src,$srcport,$dst,$dstport) =
      ($port->{src},$port->{srcport},$port->{dst},$port->{dstport});
    print "  port $p: src=$src dst=$dst\n";
  }
}
##
main: {
  ## Parse CLA
  my %opts;
  usage() unless getopts($OPTS, \%opts);
  usage(undef, 1) if $opts{h};
  $VERBOSE = $opts{V} || $opts{v};
  $| = 1;
  my $mctx = {};
  my @graphies = ();
  if (!scalar(@ARGV)) {
    @graphies = graphy($mctx,\*STDIN);
  } else {
    foreach my $f (@ARGV) {
      open(INPUT, "< $f") || die qq{$P: could not open "$f": $!\n};
      push @graphies, (graphy($mctx,\*INPUT));
      close(INPUT);
    }
  }
  foreach my $g (@graphies) {
    dump_graphy($g);
  }
}
__END__

=head1 DESCRIPTION
description of program
=cut

=head1 VERSION HISTORY
  0.1.0   dd mmm yy     attila  sample history line
=cut

##
# Local variables:
# tab-width: 2
# perl-indent-level: 2
# indent-tabs-mode: nil
# comment-column: 40
# End:
##
