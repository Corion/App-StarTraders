package App::StarTraders::StarSystem;
use strict;
use Moose;

has name => (
    is => 'ro',
    isa => 'Str',
    default => 'unnamed star',
);

has planets => (
    is => 'ro',
    isa => 'Array'
    default => [],
);

has wormholes => (
    is => 'ro',
    isa => 'Array'
    default => [],
);

no Moose;

1;