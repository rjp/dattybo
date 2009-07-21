use DBI;
use Net::Twitter::Lite;
use JSON;

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
my $metadata = $dbh->selectall_arrayref('SELECT * FROM dm_seen', {Slice=>{}});
if (defined $metadata and defined $metadata->[0]) {
    $max_id = $metadata->[0]->{'id'};
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
            $dbh->begin_work();
            $dbh->do("INSERT INTO datalog (name, key, value, logged_at) VALUES (?,?,?,CURRENT_TIMESTAMP)", undef, $from, $key, $value);
            $dbh->do("UPDATE dm_seen SET id=?", undef, $dmid);
            $dbh->commit();
            $max_id = $dmid;
        } else {
            print "$dmid <= $max_id: ignoring\n";
        }
    }
    sleep 60;
}
