=head1 NAME

Remark::Par - Description

=head1 SYNOPSIS

use Remark::Par;
blah;

=head1 DESCRIPTION

Describe the module.

=head1 AUTHOR

attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2003 by attila <attila@stalphonsos.com>.  all rights reserved.

=head1 VERSION

$Id: Par.pm,v 1.5 2003/08/09 14:49:58 attila Exp $
Time-stamp: <2003-08-09 10:38:00 EDT>

=cut

package Remark::Par;
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
sub count_words {
  return scalar((split(/[\s\.\,]+/, shift(@_))));
}
##
sub add_line {
  my $self = shift(@_);
  my $line = shift(@_);
  return unless $line;
  my $nw = count_words($line);
  push(@{$self->{lines}}, $line);
  $self->{nwords} += $nw;
  print STDERR "[P<",$self->{name},"> added $nw words (",
    scalar(@{$self->{lines}}),")]\n"
      if ($self->{context}->{VERBOSE} > 2);
  return $self;
}
##
sub append_line {
  my $self = shift(@_);
  my $text = shift(@_);
  return unless $text;
  if (!scalar(@{$self->{lines}})) {
    print STDERR "[P- append_line to empty para]\n" if ($self->{context}->{VERBOSE} > 2);
    push @{$self->{lines}}, "";
  }
  my $last_line = pop @{$self->{lines}};
  $text =~ s/^\s+//;
  my $nw = count_words($text);
  $last_line .= " $text";
  push @{$self->{lines}}, $last_line;
  $self->{nwords} += $nw;
  print STDERR "[P+<",$self->{name},"> added $nw words to last line (",
    scalar(@{$self->{lines}}),")]\n" if ($self->{context}->{VERBOSE} > 2);
  return $self;
}
##
sub get_wigglemap {
  my $self = shift(@_);
  return $self->{context}->get_wigglemap();
}
##
sub get_eltmap {
  my $self = shift(@_);
  return $self->{context}->get_eltmap();
}
##
sub output_docbook {
  my $self = shift(@_);
  my $level = shift(@_);
  my $ostream = shift(@_);
  my $i = indent($level);
  my $wigmap = $self->get_wigglemap();
  my $eltmap = $self->get_eltmap();
  my $n;
  if (!$self->marked("revision_log")) {
    print $ostream "$i<para>\n";
    my $fmtme = $self->{context}->{FormatParas} && !$self->marked("nofmt");
    if ($fmtme) {
      my($p,$tmpfile) = ($self->{context}->{P},$self->{context}->{TEMPFILE});
      open(TMP,"|fmt >$tmpfile") || die "$p: fmt: $!\n";
    }
    print STDERR "." if $self->{context}->{Dots};
    my $paratext = "$i ".join("\n$i ",@{$self->{lines}})."\n";
    $paratext =~ s/^\s+//;
    $paratext =~ s/\s+$//;
    $paratext = wiggle($paratext,$wigmap);
    $paratext = eltify($paratext,$eltmap);
    $paratext =~ s/\[\[([^\]]+)\]\]/<comment>$1<\/comment>/gs;
    $paratext =~ s/\{\{([^\}]+)\}\}/<!-- $1 -->/gs;     # comments
    print STDERR ">>$i $paratext\n" if ($self->{context}->{VERBOSE} > 3);
    if (!$fmtme) {
      print $ostream "$i $paratext\n";
    } else {
      print TMP "$i $paratext\n";
    }
    if ($fmtme) {
      close(TMP);
      my($p,$tmpfile) = ($self->{context}->{P},$self->{context}->{TEMPFILE});
      open(TMP,"< $tmpfile") || die "$p: reopening $tmpfile: $!\n";
      while (<TMP>) {
        print $ostream $_;
      }
      close(TMP);
      unlink($tmpfile);
    }
    print $ostream "$i</para>\n";
    $n = 1;
  } elsif ($self->{context}->{OutputRevisionLog}) {
    print $ostream join("\n",map{"$i<!-- $_ -->"} @{$self->{lines}}),"\n";
    $n = 1;
  } else {
    $n = 0;
  }
  return $n;
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
  return defined($self->{marks}->{$what})? 1: 0;
}
##
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $name = $args{name} || "noname Par";
  my $self =
    bless
      { name => psychochomp($name),
        lines => [],
        nwords => 0,
        marks => {},
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
