use strict;
use FileMetadata::Store::DBI;
use Test;
use DBI;

BEGIN { plan tests => 17}

#
# NOTE:
#
# The DBI_DB, DBI_USER, DBI_PASS, DBI_TABLE enviroment variables must
# be set for this test. Further, the table must be as follows
# create table foo {
#   id TEXT, timestamp TEXT, author TEXT);
#

my $database = $ENV{'DBI_DB'};
my $user = $ENV{'DBI_USER'};
my $passwd = $ENV{'DBI_PASS'};
my $table = $ENV{'DBI_TABLE'};

# 1. Test construction with verbose hash - Ok
my $config1 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'id',
			   property => 'ID'},
			  {name => 'timestamp',
			   property => 'TIMESTAMP'},
			  {name => 'author',
			   property => 'FileMetadata::Miner::HTML::author',
			   default => 'Jules Verne'}]};
my $store1;
eval {$store1 = FileMetadata::Store::DBI->new ($config1)};
ok (("$@" eq '') and defined $store1, 1);

# 2. Test with the default element omitted - Ok
my $config2 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'id',
			   property => 'ID'},
			  {name => 'timestamp',
			   property => 'TIMESTAMP'},
			  {name => 'author',
			   property => 'FileMetadata::Miner::HTML::author'}]};
my $store2;
eval {$store2 = FileMetadata::Store::DBI->new ($config2)};
ok (("$@" eq '') and defined $store2, 1);

# 3. Test with the name element of third store element omitted - Fails
my $config3 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'id',
			   property => 'ID'},
			  {name => 'timestamp',
			   property => 'TIMESTAMP'},
			  {property => 'FileMetadata::Miner::HTML::author',
			   default => 'Jules Verne'}]};
my $store3;
eval {$store3 = FileMetadata::Store::DBI->new ($config3)};
ok (! ($@ eq '') and !defined $store3);

# 4. Test with property element of third store element omitted - FAIL
my $config4 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'id',
			   property => 'ID'},
			  {name => 'timestamp',
			   property => 'TIMESTAMP'},
			  {name => 'author',
			   default => 'Jules Verne'}]};

my $store4;
eval {$store4 = FileMetadata::Store::DBI->new ($config4)};
ok (!(($@ eq '') or defined $store4));

# 5. Test with property element='ID' not present - FAIL
my $config5 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'timestamp',
			   property => 'TIMESTAMP'},
			  {name => 'author',
			   property => 'FileMetadata::Miner::HTML::author',
			   default => 'Jules Verne'}]};

my $store5;
eval {$store5 = FileMetadata::Store::DBI->new ($config5)};
ok (!(($@ eq '') or defined $store5));

# 6. Test with property element='TIMESTAMP' not present - FAIL
my $config6 = {database => $database,
	       username => $user,
	       password => $passwd,
	       table => $table,
	       column => [{name => 'id',
			  property => 'ID'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};

my $store6;
eval {$store6 = FileMetadata::Store::DBI->new ($config6)};
ok (!(($@ eq '') or defined $store6));

#
# Test store functionality with config1
#

# 7. Testing with the property FileMetadata::Miner::HTML::author omitted
my $meta1 = {ID => 'one', TIMESTAMP => '12345'};
eval {$store1->store ($meta1)};
ok ($@, '');

# 8. Testing has() on store in which a single item was inserted
my $temp = $store1->has ('one');
ok ($temp, '12345');

# 9. Testing list
my @list = @{$store1->list()};
ok (($#list == 0) and ($list[0] eq 'one'), 1);

# 10. Try to insert another item
my $meta2 = {ID => 'two', TIMESTAMP => '12346',
	     'FileMetadata::Miner::HTML::author' => 'James Scott'};
$store1->store ($meta2);
ok ($store1->has ('two'));

# 11. make sure one is in there
ok ($store1->has ('one'));

# 12. Remove one.
$store1->remove ('one');

# make sure two there and one not there
ok (!$store1->has ('one') && $store1->has ('two'));

# 13. Clear
$store1->clear ();

#make sure both 'two' and one are not there
ok (! defined $store1->has ('one') and ! defined $store1->has ('two'));

#put one back
$store1->store ($meta1);

# 14. Checking to see if the default value made it in.
$store1->finish();

# Now we establish a conection to the DB and do some querying
my $dbh = DBI->connect ($database, $user, $passwd);
my $sth = $dbh->prepare ("SELECT * FROM $table WHERE id='one'");
$sth->execute();
my $row = $sth->fetchrow_hashref ();
# 15 - 17 make sure all items are there
ok ($row->{'id'}, 'one');
ok ($row->{'timestamp'}, '12345');
ok ($row->{'author'}. 'Jules Verne');
$row = $sth->fetchrow_hashref ();

# 18. make sure there is only one row
ok (defined $row, '');

# TODO : More testing
