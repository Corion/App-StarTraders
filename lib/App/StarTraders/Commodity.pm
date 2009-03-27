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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
