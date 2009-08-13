use DBI;
use Net::Twitter::Lite;
use JSON;
use Date::Manip;
use Data::Dumper;

my $config_file = "$ENV{HOME}/.dattybo";

open C, $config_file or die "$!";
my $config = join('', <C>);
close C;

my $json = from_json($config);

# TODO get this from the config file
my $sqlite = "$ENV{HOME}/.dattybo.db";
print "connecting to $sqlite\n";

chdir($ENV{HOME});

# we assume the schema is in place already because I can't work table_info
my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite","","");

my $twitter = Net::Twitter::Lite->new(
    username => $json->{'username'},
    password => $json->{'password'},
);

# work out the maximum ID we've seen so far
my $max_id = 0;
my $metadata = $dbh->selectall_arrayref('SELECT value FROM metadata WHERE datakey="max_id"', {Slice=>{}});
if (defined $metadata and defined $metadata->[0]) {
    $max_id = $metadata->[0]->{'value'};
    print "db says max_id is $max_id\n";
}
print "max_id is $max_id\n";

while ( 1 ) {
    my $dm = $twitter->direct_messages();
    print "processing dms\n";
    foreach my $i (sort {$a->{'id'} <=> $b->{'id'}} @{$dm}) {
        # process them here if we've not seen them before
        my $from = $i->{'sender_screen_name'};
        my $dmid = $i->{'id'};
        my $text = $i->{'text'};
        my $time = $i->{'created_at'};
        my ($key, $value) = split(' ', $text, 2);

        if ($dmid > $max_id) {
            print "$dmid > $max_id: $key = $value\n";
            if ($key =~ /\?$/) { # return today's sum
                my $date = $value || 'today';
                my $fmt_date = UnixDate($date, '%Y-%m-%d');
                my $data = $dbh->selectall_hashref(qq/
                    SELECT DATE(logged_at) AS logged_date,
                           COUNT(1) AS logged, MIN(value) AS min,
                           MAX(value) AS max, AVG(value) AS avg,
                           SUM(value) AS sum
                    FROM datalog
                    WHERE DATE(logged_at) = ?
                    GROUP BY DATE(logged_at)
                /, 'logged_date', {}, $fmt_date);
                print to_json($data),"\n";
                my $d = $data->{$fmt_date};
                my $msg = $d->{logged_date}.": sum=".$d->{sum}.", n=".$d->{logged};
                if (not defined $d->{logged} or $d->{logged} < 1) {
                    $msg = $fmt_date.": no data ($value)";
                }
                $twitter->new_direct_message($from, $msg);
            } else {
                my $tv = $time;
                # insert it as a key/value pair
                if ($value =~ / (@|at) (.+)$/) {
                    $tv = $2;
                    $value =~ s/ (@|at) (.+)$//;
                }
                if (my $tp = ParseDate($tv)) {
                    $timestamp = UnixDate($tv, '%Y-%m-%d %H:%M:%S');
                } else {
                    die "unparseable timestamp: $2";
                }

                # TODO check the return value here and only update the max_id if we succeed
                # this can lead to problems if you have INSERT / QUERY, then QUERY can be run multiple times
	            $dbh->do("INSERT INTO datalog (name, datakey, value, logged_at) VALUES (?,?,?,?)", undef, $from, $key, $value, $timestamp);
            }
            $dbh->do("UPDATE metadata SET value=? WHERE datakey='max_id'", undef, $dmid);
            $max_id = $dmid;
        } else {
            print "$dmid <= $max_id: ignoring\n";
        }
    }
    sleep 120;
}
