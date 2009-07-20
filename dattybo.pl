use DBI;
use Net::Twitter::Lite;
use JSON;

my $config_file = "$ENV{HOME}/.dattybo";

open C, $config_file or die "$!";
my $config = join('', <C>);
close C;

my $json = from_json($config);

my $sqlite = ".dattybo.db";

# cygwin appears not to like $ENV{HOME} in the dbname
chdir $ENV{HOME};

my $dbh = DBI->connect("dbi:SQLite:db=$sqlite","","");
