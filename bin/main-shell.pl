#!perl -w
use strict;
use App::StarTraders::Shell;

use App::StarTraders::Demiurge;

my $demi = App::StarTraders::Demiurge->new();
my $st = $demi->new_universe;

my $widgets = $st->new_commodity( name => 'Widgets', weight => 100, volume => 10 );

my $e = $st->find_planet('Earth');
$e->deposit( $widgets => 100 );

my $ship = App::StarTraders::Ship->new( system => ($st->systems)[0], name => 'Dora', capacity => 125 );
$ship->move_to($st->find_planet('Earth'));

my $shell = App::StarTraders::Shell->new(
    universe => $st,
    ship => $ship,
)->run();
