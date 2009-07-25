use DBI;
use Net::Twitter::Lite;
use JSON;
use Date::Manip;

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
            } else {
                # insert it as a key/value pair
	            $dbh->do("INSERT INTO datalog (name, datakey, value, logged_at) VALUES (?,?,?,CURRENT_TIMESTAMP)", undef, $from, $key, $value);
            }
            $dbh->do("UPDATE metadata SET value=? WHERE datakey='max_id'", undef, $dmid);
            $max_id = $dmid;
        } else {
            print "$dmid <= $max_id: ignoring\n";
        }
    }
    sleep 60;
}
