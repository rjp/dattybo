#!/usr/bin/env perl

use DBI;
use JSON;
use Date::Manip;
use Mojolicious::Lite;

my $sqlite = "/home/rjp/.dattybo.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite","","");

get '/' => 'index';

get '/:user' => \&render_user;

get '/:user/:data' => \&render_user_data;
get '/:user/:data/(*date)' => \&render_user_data;

shagadelic('cgi');

sub render_user {
    my $self = shift;
    $self->render(text => 'u='.$self->stash('user'));
}

sub render_user_data {
    my $self = shift;
    my $date = $self->stash('date');

    my $output = $self->stash('user') . ' d='.$self->stash('data');

    if ($date) {
        $output .= " date=$date";
    }

    $self->render( text => $output );
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
