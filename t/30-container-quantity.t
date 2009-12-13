#!perl -w
use strict;
use Test::More tests => 4;

use App::StarTraders::Demiurge;
use App::StarTraders::Demiurge::CommodityPresets;

my $demi = App::StarTraders::Demiurge->new();
my $st = $demi->new_universe;
App::StarTraders::Demiurge::CommodityPresets->create_commodities(
    spacetime => $st
);

my $widgets = $st->find_commodity( 'Widgets' );
my $e = $st->find_planet('Earth');
$e->deposit( $widgets => 300 );

my $ship = App::StarTraders::Ship->new( system => ($st->systems)[0], name => 'Dora', capacity => 125 );
$ship->move_to($st->find_planet('Earth'));

ok $ship->can_pick_up($widgets, 100), 'We have capacity for 100 items';
ok !$ship->can_pick_up($widgets, 200), "We don't have capacity for 200 items";

$ship->pick_up($widgets, 100);
ok $ship->can_pick_up($widgets, 25), 'We have capacity for 24 additional items';
ok !$ship->can_pick_up($widgets, 26), "We don't have capacity for 25 additional items";
