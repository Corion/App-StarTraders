#!perl -w
use strict;
use App::StarTraders::StarSystem;
use App::StarTraders::Worm;
use App::StarTraders::Ship;

my @stars = (
    App::StarTraders::StarSystem->new(
        name => 'Sol',
        planets => [qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]],
    ),
    App::StarTraders::StarSystem->new(
        name => 'Alpha Centauri',
    ),
);

my $w = App::StarTraders::Worm->connect($stars[0], $stars[1]);

my $ship = App::StarTraders::Ship->new( system => $stars[0], name => 'Dora' );
describe_system($ship->system);
$ship->enter(($ship->system->wormholes)[0]);
describe_system($ship->system);

sub describe_system {
    my ($star) = @_;
    
    print $star->name,"\n";
    print "\t$_\n" for $star->planets;
    print "Wormholes:\n";
    print( "\t", $_->target_system->name, "\n" ) for $star->wormholes;
};