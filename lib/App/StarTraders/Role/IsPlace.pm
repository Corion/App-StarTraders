package App::StarTraders::Role::IsPlace;
use strict;
use Moose::Role;

has name => (
    is => 'rw',
    isa => 'Str',
    default => 'unnamed entity',
);

1;