#!/usr/bin/env perl

use Mojolicious::Lite;

get '/' => 'index';

get '/:user' => \&render_user;

get '/:user/:data' => \&render_user_data;

shagadelic('cgi');

sub render_user {
    my $self = shift;
    $self->render(text => 'u='.$self->stash('user'));
}

sub render_user_data {
    my $self = shift;
    $self->render(text => $self->stash('user') . ' d='.$self->stash('data'));
}

__DATA__

@@ index.html.eplite
% my $self = shift;
% $self->stash(layout => 'funky');
Yea baby!

@@ layouts/funky.html.eplite
% my $self = shift;
<!html>
    <head><title>Funky!</title></head>
    <body>
        <%= $self->render_inner %>
    </body>
</html>
