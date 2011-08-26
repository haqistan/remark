=head1 NAME

Remark::Context - Description

=head1 SYNOPSIS

use Remark::Context;
blah;

=head1 DESCRIPTION

Describe the module.

=head1 AUTHOR

attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2003 by attila <attila@stalphonsos.com>.  all rights reserved.

=head1 VERSION

$Id: Context.pm,v 1.3 2003/08/09 14:49:54 attila Exp $
Time-stamp: <2003-09-22 18:32:29 EDT attila@stalphonsos.com>

=cut

package Remark::Context;
use strict;
use Carp;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUGGING $TESTING);
$VERSION = q{0.1.0};
@ISA = qw(Exporter);
@EXPORT_OK = qw();
@EXPORT = @EXPORT_OK;
$DEBUGGING = 0;
$TESTING = 0;

use Remark::Utils;

=head1 DETAILED DOCUMENTATION

This class exports the following interface:

=head2 new [args=>vals]

=cut

sub try_file {
  my($dir,$fn) = @_;
  my $ffn = qq{$dir/$fn};
  return $ffn if -f $ffn;
  return undef;
}

sub find_map_file {
  my $self = shift(@_);
  my $name = shift(@_);
  my $fname = $name . '.rmap';
  my $f = try_file('./.remark', $fname);
  $f ||= try_file('.', '.' . $fname);
  $f ||= try_file($ENV{'HOME'} . '/.remark', $fname);
  $f ||= try_file($ENV{'HOME'}, '.' . $fname);
  return $f;
}

sub read_map_file {
  my $self = shift(@_);
  my($map,$file) = @_;
  open(MAP, "< $file") || die qq{could not open map file "$file": $!\n};
  $self->printv(1,qq{[Loading map: $file]});
  my($nlines,$nents) = (0,0);
  while (<MAP>) {
    chomp;
    ++$nlines;
    next if /^\#/;
    next if /^\s*$/;
    next unless /^(\S.*)\s=>\s(.*)$/;
    my($key,$val) = ($1,$2);
    $key = psychochomp($key);
    next unless length $key;
    $val = psychochomp($val);
    if (!length($val)) {
      mapdel($map,$key);
    } else {
      mapadd($map,$key,$val);
    }
    ++$nents;
  }
  close(MAP);
  $self->printv(1,qq{[Loaded map $file: $nents entries in $nlines lines]});
}

sub get_merged_map {
  my $self = shift(@_);
  my $mapname = shift(@_);
  my $map;
  if (defined($self->{MAPS}->{$mapname})) {
    $map = $self->{MAPS}->{$mapname};
  } else {
    $map = mapclone($mapname);
    my $mapfile = $self->find_map_file($mapname);
    $self->read_map_file($map, $mapfile) if defined $mapfile;
    $self->{MAPS}->{$mapname} = $map;
  }
  return $map;
}

sub get_wigglemap {
  my $self = shift(@_);
  return $self->get_merged_map('wiggle');
}

sub get_eltmap {
  my $self = shift(@_);
  return $self->get_merged_map('elt');
}

sub printv {
  my $self = shift(@_);
  my $level = shift(@_);
  return undef unless $self->{VERBOSE} >= $level;
  print STDERR "@_\n";
}

sub init_graphy_stuff {
}

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $self =
    { VERBOSE => $args{'verbosity'},
      Type => $args{'type'},
      OutputRevisionLog => $args{'revision_log'},
      OutputUn => $args{'unnamed'},
      Dots => $args{'dots'},
      FormatParas => $args{'format_paras'},
      SideMaterial => $args{'side_material'},
      NoPreface => $args{'no_preface'},
      MAX_BULLET_WORDS => $args{'max_bullet_words'} || $MAX_BULLET_WORDS,
      P => $args{'program'} || $main::P,
      VERSION => $args{'version'} || $main::VERSION,
      MAPS => {},
      DTD => "-//OASIS//DTD DocBook V3.1//EN",
      ROOT_ELT => "book",
    };
  bless($self, $class);
  return $self;
}
##
1;
__END__
##
# Local variables:
# tab-width: 2
# perl-indent-level: 2
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
