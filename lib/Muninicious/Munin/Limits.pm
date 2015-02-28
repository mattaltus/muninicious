package Muninicious::Munin::Limits;

use strict;
use warnings;

use base qw/Muninicious::Munin::File/;

use File::Spec::Functions qw/catfile/;
use Carp qw/croak/;

sub new {
  my ($class, $args) = @_;

  my $self = $class->SUPER::new('limits', $args);

  $self->{'data'} = $self->_parse($self->{'filename'});

  return $self;
}

sub _parse {
  my ($self, $filename) = @_;

  my $data = {};
  open(my $fd, "<", $filename) || croak "Error opening file '$filename': $!";
  while (<$fd>) {
    chomp;
    next if (/^version\s/i);
    my ($key, @values) = split(/\s/, $_);
    my ($group, $host, $graph, $field) = split(/;/, $key);
    $data->{$group}->{$host}->{$graph}->{$field} = join(' ', @values);
  }
  close ($fd);

  return $data;
}


1;