#!perl -w
use strict;
use App::StarTraders::StarSystem;

my @stars = (
    App::StarTraders::StarSystem->new(
        name => 'Sol',
        planets => [qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]],
    ),
    App::StarTraders::StarSystem->new(
        name => 'Alpha Centauri',
    ),
);



for my $star (@stars) {
    print $star->name,"\n";
    print "\t$_\n" for $star->planets;
    print "Wormholes:\n";
    print( "\t", $_->target->name, "\n" ) for $star->wormholes;
};