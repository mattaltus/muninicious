package Muninicious::Munin::File;

use strict;
use warnings;

use File::Spec::Functions qw/catfile/;

sub new {
  my ($class, $name, $args) = @_;

  my $self = bless({}, $class);

  $self->{'DBDIR'}     = $args->{'dbdir'};
  $self->{'FILENAME'}  = catfile($args->{'dbdir'}, $name);
  $self->{'TIMESTAMP'} = $self->get_ts();
  $self->{'DATA'}      = $self->_parse($self->{'FILENAME'});

  return $self;
}

sub get_ts {
  my ($self) = @_;
  return (stat($self->{'FILENAME'}))[9];
}

sub reload {
  my ($self, $force) = @_;

  my $current_ts = $self->get_ts();
  if ($force || $current_ts > $self->{'TIMESTAMP'}) {
    warn "RELOAD: $self->{'FILENAME'}";
    $self->{'TIMESTAMP'} = $self->get_ts();
    $self->{'DATA'}      = $self->_parse($self->{'FILENAME'});
  }

  return;
}

1;