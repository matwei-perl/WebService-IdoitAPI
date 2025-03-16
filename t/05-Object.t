#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Storable qw( retrieve );

use_ok( 'WebService::IdoitAPI::Object' );

my $api = WebService::IdoitAPI->new({
    apikey => 'something',
    url => 'http://localhost',
});
my $object = WebService::IdoitAPI::Object->new($api);

my $info = retrieve('t/data/05-object-944.nstore');

$object->{info} = $info;
$object->{id} = 944;

my $data = $object->get_addresses();

ok(632 == $data->{'10.20.0.1'}->{net_id},'10.20.0.1 belongs to net_id 632');
ok($data->{'10.20.0.1'}->{standard_gateway},'10.20.0.1 is standard gateway');
ok($data->{'10.20.0.1'}->{primary},'10.20.0.1 is primary');
ok('C__CATS_NET_TYPE__IPV4' eq $data->{'10.20.0.1'}->{type_const},"10.20.0.1 is 'C__CATS_NET_TYPE__IPV4'");
ok(20 == $data->{'23.23.23.23'}->{net_id},'23.23.23.23 belongs to net_id 20');
ok(0 == $data->{'23.23.23.23'}->{standard_gateway},'23.23.23.23 is not standard gateway');

done_testing();
