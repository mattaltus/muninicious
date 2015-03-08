package Muninicious::Munin::State;

use strict;
use warnings;

use Mojo::Base -base;

use constant {
  STATE_ENUM => {
    ok       => 0,
    unknown  => 1,
    warning  => 2,
    critical => 3,
  },
};

use overload
  '>' => \&greater_than,
  '<' => \&less_than;

has group         => undef;
has host          => undef;
has service       => undef;
has child_service => undef;
has field         => undef;
has state         => undef;
has message       => undef;



sub greater_than {
  my ($a, $b) = @_;

  my $a_val = &STATE_ENUM->{'$a->state'} || 99;
  my $b_val = &STATE_ENUM->{'$b->state'} || 99;

  return 1 if ($a_val > $b_val);
  return 0;
}

sub less_than {
  my ($a, $b) = @_;

  my $a_val = &STATE_ENUM->{'$a->state'} || 99;
  my $b_val = &STATE_ENUM->{'$b->state'} || 99;

  return 1 if ($a_val < $b_val);
  return 0;
}

sub get_class {
  my ($self) = @_;

  return 'danger'  if ($self->state eq 'critical');
  return 'warning' if ($self->state eq 'warning');
  return 'default';
}







1;