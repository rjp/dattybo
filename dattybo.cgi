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
    my $user = $self->stash('user');
    my $data = $self->stash('data');

    my @where = ('name=?', 'datakey=?');
    my @bvars = ($user, $data);

    my ($min_date, $max_date, $dates) = make_date_range($date);

    push @where, "date(logged_at) between ? and ?";
    push @bvars, $min_date, $max_date;

    my $where = join(' AND ', @where);
    my $query = qq/
        SELECT DATE(logged_at) AS logged_date,
               COUNT(1) AS logged, MIN(value) AS min,
               MAX(value) AS max, AVG(value) AS avg,
               SUM(value) AS sum
        FROM datalog
        WHERE $where
        GROUP BY DATE(logged_at)
    /;

    my $d = $dbh->selectall_hashref($query, 'logged_date', {}, @bvars);
    my @o = sort keys %{$d};

    my @range = @{$dates};

    my $min_val = 1e100;
    my $max_val = -$min_val;

    my @values = ();
    my $count = 0;
    foreach my $i (@range) {
        my $x = $d->{$i}->{'sum'};
        if ($x < $min_val) { $min_val = $x; }
        if ($x > $max_val) { $max_val = $x; }
        push @values, $d->{$i}->{'sum'};
        $count++;
    }

    my $count = scalar @range;
    my @dlabels = ($range[0], $range[-1]);
    my @dpos = (0, $count);

    if ($count > 10) {
        my $span = int($count / 3);
        @dlabels = ($range[0], $range[$span], $range[2*$span], $range[-1]);
        @dpos = (0.5, 0.5+$span, 0.5+2*$span, 0.5+$count);
    }

    my $dl = join('|', @dlabels);
    my $dp = join(',', @dpos);

    my $chart = "http://chart.apis.google.com/chart?chxl=0:|$dl|1:|750|1000|1250|1500|2000&chxp=0,$dp|1,750,1000,1250,1500,2000&chxs=0,888888,9|1,888888,9,1,lt,cccccc&chs=240x100&chxt=x,y&chxtc=0,6|1,-220&chxr=1,750,2000,0|0,0,31,0&cht=bvg&chbh=a,0,0&chco=88CCFF&chds=750,2000&chd=t:";
    $chart .= join(',', map { defined $_ ? $_ : 0 } @values);

    $self->stash(c_keys => \@range);
    $self->stash(c_data => $d);
    $self->stash(c_chart => $chart);

    $self->render( template => 'counter' );
}

sub make_chart {
     my $data = shift;
}

sub make_date_range {
    my $date_part = shift;
    my ($min, $max);

    if (not defined $date_part) {
        $max = UnixDate(ParseDate('today'), '%Y-%m-%d');
        $min = UnixDate(ParseDate('30 days ago'), '%Y-%m-%d');
    } else {
        my ($year, $month, $day) = split('/', $date_part);

	    if (defined $day) {
	        ($min = $date_part) =~ s!/!-!g;
            $max = $min;
	    }
        elsif (defined $month) {
            $max = UnixDate(DateCalc("$year-$month-01", "+1 month -1 day"), "%Y-%m-%d");
            $min = "$year-$month-01";
        }
        elsif (defined $year) {
            $max = "$year-12-31";
            $min = "$year-01-01";
        }
    }

    # Date::Manip recurs $min <= $date < $max so we extend
    my $extend = DateCalc($max, '+1 day');
    my @range =
        map { UnixDate($_, '%Y-%m-%d') }
        ParseRecur('0:0:0:1:0:0:0', $min, $min, $extend);

    return $min, $max, \@range;
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
    <style><!--
table.data {
    font-size: small;
    border-width: 1px 1px 1px 1px;
    border-spacing: 1px;
    border-style: dotted dotted dotted dotted;
    border-color: gray gray gray gray;
    border-collapse: collapse;
    background-color: white;
}
table.data th {
    border-width: 1px 1px 1px 1px;
    padding: 2px 2px 2px 2px;
    border-style: dotted dotted dotted dotted;
    border-color: gray gray gray gray;
    background-color: white;
    -moz-border-radius: 0px 0px 0px 0px;
}
table.data td {
    border-width: 1px 1px 1px 1px;
    padding: 2px 2px 2px 2px;
    border-style: dotted dotted dotted dotted;
    border-color: gray gray gray gray;
    background-color: white;
    -moz-border-radius: 0px 0px 0px 0px;
}
--></style>
    <body>
        <%= $self->render_inner %>
    </body>
</html>

@@ counter.html.eplite
% my $self = shift;
% $self->stash(layout => 'funky');
<img src="<%= $self->stash('c_chart') %>">
<hr>
<table class="data"><tr><th>Date<th>Total<th>Items
% foreach my $i (@{$self->stash('c_keys')}) {
% my $d = $self->stash('c_data')->{$i};
<tr>
 <td><%= $i %>
 <td><%= $d->{'sum'} %>
 <td><%= $d->{'logged'} %>
</tr>
% }
</table>
