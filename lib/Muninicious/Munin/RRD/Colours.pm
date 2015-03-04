package Muninicious::Munin::RRD::Colours;

use strict;
use warnings;

use Mojo::Base -base;


use constant {
  PALETTE => [qw(
    00CC00 0066B3 FF8000 FFCC00 330099 990099 CCFF00 FF0000 808080
    008F00 00487D B35A00 B38F00         6B006B 8FB300 B30000 BEBEBE
    80FF80 80C9FF FFC080 FFE680 AA80FF EE00CC FF8080
    666600 FFBFFF 00FFCC CC6699 999900
  )],
};

has palette_index => 0;
has graph_colours => sub { return {} };

sub get_next_colour {
  my ($self) = @_;

  my $index = $self->palette_index();
  $index = 0 if ($index >= scalar @{&PALETTE});

  my $colour = &PALETTE->[$index++];

  $self->palette_index($index);

  return $colour;
}

sub get_field_colour {
  my ($self, $field) = @_;
  my $colour = $field->metadata('colour') || $field->metadata('color');

  $colour = $self->graph_colours->{$field->name} if (!defined $colour);
  my $neg_field = $field->get_negative();
  $colour = $self->graph_colours->{$neg_field->name} if (!defined $colour && defined $neg_field);
  $colour = $self->get_next_colour if (!defined $colour);

  $self->graph_colours->{$neg_field->name} = $colour if (defined $neg_field);
  $self->graph_colours->{$field->name} = $colour;

  return $colour;
}

1;