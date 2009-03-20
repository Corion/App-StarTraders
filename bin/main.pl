#!perl -w
use strict;
use App::StarTraders::SpaceTime;
#use App::StarTraders::StarSystem;
#use App::StarTraders::Worm;
use App::StarTraders::Ship;
use App::StarTraders::Planet;

sub planets {
    map { App::StarTraders::Planet->new( name => $_ ) } @_
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
        name => 'Unnamed system',
        planets => [planets( qw[unnamedPlanet1 unnamedPlanet2])],
);

$st->new_wormhole( 0,1 );
$st->new_wormhole( 1,2 );

my $ship = App::StarTraders::Ship->new( system => ($st->systems)[0], name => 'Dora' );
describe_system($ship->system);
$ship->enter(($ship->system->wormholes)[0]);
describe_system($ship->system);
$ship->enter(($ship->system->wormholes)[1]);
describe_system($ship->system);

# Now, enter the orbit of unnamedPlanet1
#$ship->enter(($ship->system->wormholes)[0]);

sub describe_system {
    my ($star) = @_;
    
    print $star->name,"\n";
    for ($star->planets) {
        print "\t", $_->name, "\n";
    };
    print "Wormholes:\n";
    print( "\t", $_->target_system->name, "\n" ) for $star->wormholes;
};