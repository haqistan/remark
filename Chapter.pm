=head1 NAME

Remark::Chapter - Description

=head1 SYNOPSIS

use Remark::Chapter;
blah;

=head1 DESCRIPTION

Describe the module.

=head1 AUTHOR

attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2003 by attila <attila@stalphonsos.com>.  all rights reserved.

=head1 VERSION

$Id: Chapter.pm,v 1.1 2003/07/20 01:55:50 attila Exp $
Time-stamp: <2003-07-16 20:03:15 EDT>

=cut

package Remark::Chapter;
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
sub add_par {
  my $self = shift(@_);
  my $par = shift(@_);
  print STDERR "[C<",$self->{name},"> add_par $par]\n"
    if ($self->{context}->{VERBOSE} > 1);
  return unless $par;
  push(@{$self->{contents}}, $par);
  $self->{nwords} += $par->{nwords};
  $self->{nparagraphs}++;
  print STDERR "[S<",$self->{name},"> added ",$par->{nwords}," (",
    scalar(@{$self->{contents}}),")]\n"
      if ($self->{context}->{VERBOSE} > 1);
  return $self;
}
##
sub add_sect {
  my $self = shift(@_);
  my $sect = shift(@_);
  return unless $sect;
  push(@{$self->{contents}}, $sect);
  $self->{nwords} += $sect->{nwords};
  $self->{nparagraphs} += scalar(@{$sect->{paragraphs}});
  return $self;
}
##
sub output_docbook {
  my $self = shift(@_);
  my $level = shift(@_);
  my $ostream = shift(@_);
  my $ispref = shift(@_);
  return if ($self->{context}->{NoPreface} && $ispref);
  my($tag,$c1,$c2) = $ispref? ("preface","{","}"): ("chapter","[","]");
  my $i = indent($level);
  return if (($self->{name} =~ /^unnamed/i) &&
             !$self->{context}->{OutputUn});
  return if (($self->{name} =~ /side\smaterial/i) &&
             !$self->{context}->{SideMaterial});
  my $nnamed = 0;
  foreach my $sect (@{$self->{contents}}) {
    ++$nnamed if ($sect->{name} !~ /^unnamed/);
  }
  return if (!$nnamed && !$self->{context}->{OutputUn});
  print $ostream "$i<$tag>\n  <title>",$self->{name},"</title>\n";
  my $secs = defined($self->{sections})? $self->{sections}: [];
  print $ostream "$i <!-- CHAP:",
    scalar(@$secs)," sects, ",$self->{nparagraphs}," pars ",
      $self->{nwords}," words -->\n";
  print STDERR $c1 if $self->{context}->{Dots};
  foreach my $sect (@{$self->{contents}}) {
    $sect->output_docbook($level+1,$ostream);
  }
  print $ostream "$i</$tag>\n";
  print STDERR $c2 if $self->{context}->{Dots};
}
##
sub mark {
  my $self = shift(@_);
  foreach my $m (@_) {
    $self->{marks}->{$m}++;
  }
}
##
sub marked {
  my $self = shift(@_);
  my $what = shift(@_);
  return 0 unless $what;
  return defined($self->{marks}->{$what});
}
##
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $name = $args{name} || "unnamed Chapter";
  my $self =
    bless
      { name => psychochomp($name),
        contents => [],
        nparagraphs => 0,
        nwords => 0,
        marks => {},
        context => $args{'context'},
      }, $class;
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
