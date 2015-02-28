package Muninicious::Munin::File;

use strict;
use warnings;

use File::Spec::Functions qw/catfile/;

sub new {
  my ($class, $name, $args) = @_;

  my $self = bless({}, $class);

  $self->{'dbdir'}     = $args->{'dbdir'};
  $self->{'filename'}  = catfile($args->{'dbdir'}, $name);
  $self->{'timestamp'} = $self->get_ts();
  $self->{'data'}      = $self->_parse($self->{'filename'});

  return $self;
}

sub get_ts {
  my ($self) = @_;
  return (stat($self->{'filename'}))[9];
}

sub reload {
  my ($self, $force) = @_;

  my $current_ts = $self->get_ts();
  if ($force || $current_ts > $self->{'timestamp'}) {
    $self->{'timestamp'} = $self->get_ts();
    $self->{'data'}      = $self->_parse($self->{'filename'});
  }

  return;
}

1;