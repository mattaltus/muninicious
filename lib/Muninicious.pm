package Muninicious;
use Mojo::Base 'Mojolicious';

use Muninicious::Munin::Config;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  my $config = Muninicious::Munin::Config->new('/etc/munin/munin.conf');
  $self->defaults('config' => $config);

  $self->hook(before_dispatch => sub {
    my $c = shift;
    $c->stash('config')->reload();
  });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('munin#home');
}



1;
