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
    foreach my $i (@{$dm}) {
        # process them here if we've not seen them before
        my $from = $dm->{'sender_screen_name'};
        my $dmid = $dm->{'id'};
        my $text = $dm->{'text'};
        my ($key, $value) = split(' ', $text, 2);
    }
    sleep 60;
}
