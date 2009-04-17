#!perl -w
use strict;
use App::StarTraders::Shell;

use App::StarTraders::SpaceTime;
use App::StarTraders::Ship;
use App::StarTraders::Planet;

sub planets {
    map { App::StarTraders::Planet->new( $_ ? (name => $_) : () ) } @_
};

my $st = App::StarTraders::SpaceTime->new();

$st->new_system(
        name => 'Sol',
        planets => [ planets( qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]) ],
);
$st->new_system(
        name => 'Alpha Centauri',
);
$st->new_system(
        planets => [planets( undef, undef)],
);

$st->new_wormhole( 0,1 );
$st->new_wormhole( 1,2 );

my $widgets = $st->new_commodity( name => 'Widgets', weight => 100, volume => 10 );

my $e = $st->find_planet('Earth');
$e->deposit( $widgets => 100 );

my $ship = App::StarTraders::Ship->new( system => ($st->systems)[0], name => 'Dora', capacity => 125 );
$ship->move_to($st->find_planet('Earth'));

my $shell = App::StarTraders::Shell->new(
    universe => $st,
    ship => $ship,
)->run();
