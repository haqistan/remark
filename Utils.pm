=head1 NAME

Remark::Utils - Description

=head1 SYNOPSIS

use Remark::Utils;
blah;

=head1 DESCRIPTION

Describe the module.

=head1 AUTHOR

attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2003 by attila <attila@stalphonsos.com>.  all rights reserved.

=head1 VERSION

$Id: Utils.pm,v 1.4 2003/08/12 22:06:25 attila Exp $
Time-stamp: <2003-08-09 18:14:55 EDT>

=cut

package Remark::Utils;
use strict;
use Carp;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUGGING $TESTING $TEMPFILE
            $L1BULLET $L2BULLET $L3BULLET $L0BULLET $MAX_BULLET_WORDS
            %DEFAULT_CHENT_MAP %DEFAULT_WIGGLE_MAP %DEFAULT_CHELT_MAP
            %MAPMAP
           );
$VERSION = q{0.1.0};
@ISA = qw(Exporter);
@EXPORT_OK =
  qw($TEMPFILE $L1BULLET $L2BULLET $L3BULLET $L0BULLET $MAX_BULLET_WORDS
     &psychochomp &indent &subify &mapord &mapadd &subify &wiggle
     &eltify &eltify1 &mapclone &exclude &mapdel
    );
@EXPORT = @EXPORT_OK;
$DEBUGGING = 0;
$TESTING = 0;
$TEMPFILE = ($ENV{'TMPDIR'} || "/tmp")."/remark-$$.tmp";
## Such a kludge...
$L0BULLET = '&bull;';
$L1BULLET = '&emsp;&bull;';
$L2BULLET = '&emsp;&emsp;&bull;';
$L3BULLET = '&emsp;&emsp;&emsp;&bull;';
$MAX_BULLET_WORDS = 6;
%DEFAULT_CHENT_MAP =
  ( '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '%%' => $L0BULLET,
    '%%%' => $L1BULLET,
    '%%%%' => $L2BULLET,
    '%%%%%' => $L3BULLET,
    _ORDER => [ '&', '%%%%%', '%%%%', '%%%', '%%', '<', '>' ], );
%DEFAULT_WIGGLE_MAP =
  ( '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '%%' => $L0BULLET,
    '%%%' => $L1BULLET,
    '%%%%' => $L2BULLET,
    '%%%%%' => $L3BULLET,
    '~~(\d+):([^~]+)~~'
    => '<inlinegraphic width="$1" depth="$1" fileref="$2"></inlinegraphic>',
    '~~(\d+),(\d+):([^~]+)~~'
    => '<inlinegraphic width="$1" depth="$2" fileref="$3"></inlinegraphic>',
    '~~([^~]+)~~'
    => '<inlinegraphic fileref="$1"></inlinegraphic>',
    _ORDER =>
    [ '&', '%%%%%', '%%%%', '%%%', '%%', '<', '>',
      '~~(\d+):([^~]+)~~', '~~(\d+),(\d+):([^~]+)~~', '~~([^~]+)~~', ], );
%DEFAULT_CHELT_MAP =
  ( '\x2a' => 'emphasis',
    '_' => 'literal',
    '\x24\x24' => 'keycap', );
%MAPMAP =
  ( 'elt' => \%DEFAULT_CHELT_MAP,
    'wiggle' => \%DEFAULT_WIGGLE_MAP, );

=head1 DETAILED DOCUMENTATION

This class exports the following interface:

=cut

=head2 psychochomp $string

=cut

sub psychochomp {
  my $str = "@_";
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

=head2 indent $n

=cut

sub indent {
  my $n = shift(@_) || 0;
  return " " x $n;
}

sub mapord {
  my $map = shift(@_);
  my @keys;
  if (defined($map->{_ORDER})) {
    @keys = @{$map->{_ORDER}};
  } else {
    @keys = (keys %$map);
    $map->{_ORDER} = [ @keys ];
  }
  return @keys;
}

sub mapclone {
  my $name = lc(shift(@_));
  return { _ORDER => [] } unless defined $MAPMAP{$name};
  my $clone = { %{$MAPMAP{$name}} };
  mapord($clone);
  return $clone;
}

sub mapadd {
  my $map = shift(@_);
  my $key = shift(@_);
  my $val = shift(@_);
  if (defined($map->{$key})) {
    $map->{$key} = $val;
  } else {
    $map->{$key} = $val;
    push @{$map->{_ORDER}}, $key;
  }
  return $map;
}

sub mapdel {
  my($map,$key) = @_;
  if (($key ne '_ORDER') && defined($map->{$key})) {
    my $ord = exclude($key,$map->{_ORDER});
    delete $map->{$key};
    $map->{_ORDER} = $ord;
  }
  return $map;
}

sub subify {
  my $str = shift(@_);
  my $map = shift(@_);
  return $str unless defined $map;
  my @keys = mapord($map);
  foreach my $ch (@keys) {
    my $sub = $map->{$ch};
    $sub =~ s/\//\\\//g;
    my $subcode = q{$str =~}.qq{ s/$ch/$sub/gs};
    eval $subcode;
  }
  return $str;
}

=head2 chentify $str[,$map]

Turn odd characters in $str into XML/HTML character entities (DEP)

=cut

sub chentify {
  my $str = shift(@_);
  my $map = shift(@_) || \%DEFAULT_CHENT_MAP;
  return subify($str,$map);
}

=head2 wiggle $text[,$map]

=cut

sub wiggle {
  my $str = shift(@_);
  my $map = shift(@_) || \%DEFAULT_WIGGLE_MAP;
  return subify($str,$map);
}

=head2 eltify $text[,$map]

=cut

sub eltify1 {
  my($text,$tag,$marker) = @_;
  my $stag = qq|<$tag>|;
  my $etag = qq|</$tag>|;
  my $qmarker = ($marker =~ /^\\/)? $marker: qq|\\$marker|;
  my $regexp = '(^\s*)'.$qmarker.'(.*)'.$qmarker.'(\s*$)';
  if ($text =~ /$regexp/s) {
    my($leadsp,$meat,$trailsp) = ($1,$2,$3);
    $text = $leadsp . $stag . $meat . $etag . $trailsp;
    return $text;
  }
  my $gutsre = '([^' . $marker . ';\.!\?]+)';
  $regexp = $qmarker . $gutsre . $qmarker;
  $text =~ s/$regexp/$stag$1$etag/g;
  return $text;
}

sub eltify {
  my $str = shift(@_);
  my $map = shift(@_);
  my @keys = mapord($map);
  foreach my $k (@keys) {
    my $tag = $map->{$k};
    $str = eltify1($str,$tag,$k);
  }
  return $str;
}

=head2 exclude $thing,...

Given a thing and an array, return a new array excluding the thing.
We use eq for equality testing.  This is not LISP.  Get over it.

=cut

sub exclude {
  my $thing = shift(@_);
  my $wasref = 0;
  if (ref($_[0]) eq 'ARRAY') {
    $wasref = 1;
    @_ = @$_[0];
  }
  my @rez = ();
  foreach (@_) {
    push(@rez, $_) unless ("$_" eq $thing);
  }
  return $wasref? [ @rez ]: @rez;
}

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
