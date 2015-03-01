package Muninicious;
use Mojo::Base 'Mojolicious';

use Muninicious::Munin::Config;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = Muninicious::Munin::Config->new('/etc/munin/munin.conf');
  $self->defaults('config' => $config);

  $self->hook(before_dispatch => sub {
    my $c = shift;
    $c->stash('config')->reload();
    $c->stash('datafile' => $c->stash('config')->getDatafile());
  });

  # Router
  my $r = $self->routes;

  $r->get('/')->to(controller => 'munin', action => 'home');

  $r->get('/page/:group/#host/:cat')->to(controller => 'munin', action => 'page', host => '*', group => '*', cat => '*');

  $r->get('graph/:group/#host/:service/:type')->to(controller => 'munin', action => 'graph', type => 'day');
}



1;
