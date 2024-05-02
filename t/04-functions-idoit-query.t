#!perl
#
use 5.010;
use strict;
use warnings;

use Test::More;

use lib "bin";
require 'idoit-query.pl';

my ($config,$query);

$ARGV[0] = '{"test":"$ARGV[0]"}';
$query = get_query($config);
ok($query->{test} eq '$ARGV[0]', 'Testing with $ARGV[0]');

$config->{opt}->{file} = 't/data/04-functions-idoit-query.json';
$query = get_query($config);
ok($query->{test} eq 'from file', 'Testing from file');

done_testing;
