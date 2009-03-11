package App::StarTraders::Role::HasName;
use strict;
use Moose::Role;

has name => (
    is => 'rw',
    isa => 'Str',
    default => 'unnamed entity',
);

1;