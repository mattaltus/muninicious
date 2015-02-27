package Muninicious::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub home {
  my $self = shift;

  my $config = $self->stash('config');

  $self->render(template => 'home');
}

1;
