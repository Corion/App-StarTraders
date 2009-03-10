package App::StarTraders::StarSystem;
use strict;
use Moose;

has name => (
    is => 'ro',
    isa => 'Str',
);

has planets => (
    is => 'ro',
    isa => 'Array'
);

has wormholes => (
    is => 'ro',
    isa => 'Array'
);

no Moose;

1;