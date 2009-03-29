package App::StarTraders::Commodity;
use strict;
use Moose;

has name => (
    is => 'rw',
    isa => 'Str',
);

has weight => (
    is => 'rw',
    isa => 'Int',
);

has volume => (
    is => 'rw',
    isa => 'Int',
);

has stackable => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
