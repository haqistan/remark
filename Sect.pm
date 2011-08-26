=head1 NAME

Remark::Sect - Description

=head1 SYNOPSIS

use Remark::Sect;
blah;

=head1 DESCRIPTION

Describe the module.

=head1 AUTHOR

attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2003 by attila <attila@stalphonsos.com>.  all rights reserved.

=head1 VERSION

$Id: Sect.pm,v 1.1 2003/07/20 01:55:56 attila Exp $
Time-stamp: <2003-07-05 00:32:34 EDT>

=cut

package Remark::Sect;
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
  print STDERR "[S<",$self->{name},"> add_par $par]\n" if ($self->{context}->{VERBOSE} > 1);
  return unless $par;
  push(@{$self->{paragraphs}}, $par);
  $self->{nwords} += $par->{nwords};
  print STDERR "[S<",$self->{name},"> added ",$par->{nwords}," (",scalar(@{$self->{paragraphs}}),")]\n"
    if ($self->{context}->{VERBOSE} > 1);
  return $self;
}
##
sub output_docbook {
  my $self = shift(@_);
  my $level = shift(@_);
  my $ostream = shift(@_);
  my $i = indent($level);
  return if (($self->{name} =~ /^unnamed/i) && !$self->{context}->{OutputUn});
  return if (($self->{name} =~ /side\smaterial/i) &&
             !$self->{context}->{SideMaterial});
  print STDERR "<" if $self->{context}->{Dots};
  print $ostream "$i<section>\n  <title>",$self->{name},"</title>\n";
  print $ostream "$i <!-- SECT:",
    scalar(@{$self->{paragraphs}})," paras, ",$self->{nwords}," words -->\n";
  my $n = 0;
  foreach my $par (@{$self->{paragraphs}}) {
    $n += $par->output_docbook($level+1,$ostream);
  }
  print $ostream "$i <para><comment>Empty section</comment</para>\n" unless $n;
  print STDERR ">" if $self->{context}->{Dots};
  print $ostream "$i</section>\n";
}
##
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $name = $args{name} || "unnamed Sect";
  my $self =
    bless
      { name => psychochomp($name),
        paragraphs => [],
        nwords => 0,
        context => $args{context},
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
