use DBI;
use Net::Twitter::Lite;
use JSON;

my $config_file = "$ENV{HOME}/.dattybo";

open C, $config_file or die "$!";
my $config = join('', <C>);
close C;

my $json = from_json($config);

# TODO get this from the config file
my $sqlite = ".dattybo.db";

# cygwin appears not to like $ENV{HOME} in the dbname
chdir $ENV{HOME};

# we assume the schema is in place already because I can't work table_info
my $dbh = DBI->connect("dbi:SQLite:db=$sqlite","","");

my $twitter = Net::Twitter::Lite->new(
    username => $json->{'username'},
    password => $json->{'password'},
);

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
