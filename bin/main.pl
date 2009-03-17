#!perl -w
use strict;
use App::StarTraders::StarSystem;
use App::StarTraders::Worm;
use App::StarTraders::Ship;
use App::StarTraders::Planet;

sub planets {
    map { App::StarTraders::Planet->new( name => $_ ) } @_
};

my @stars = (
    App::StarTraders::StarSystem->new(
        name => 'Sol',
        planets => [ planets( qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]) ],
    ),
    App::StarTraders::StarSystem->new(
        name => 'Alpha Centauri',
    ),
    App::StarTraders::StarSystem->new(
        name => 'Unnamed system',
        planets => [planets( qw[unnamedPlanet1 unnamedPlanet2])],
    ),
);

my $w = App::StarTraders::Worm->connect($stars[0], $stars[1]);
my $w1 = App::StarTraders::Worm->connect($stars[1], $stars[2]);

my $ship = App::StarTraders::Ship->new( system => $stars[0], name => 'Dora' );
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
    print "\t", $_->name, "\n" for $star->planets;
    print "Wormholes:\n";
    print( "\t", $_->target_system->name, "\n" ) for $star->wormholes;
};