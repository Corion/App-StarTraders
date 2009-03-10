#!perl -w
use strict;
use App::StarTraders::StarSystem;

my @stars = (
    App::StarTraders::StarSystem->new(
        name => 'Sol',
    ),
);

print $stars[0]->name;
print for $stars[0]->planets;