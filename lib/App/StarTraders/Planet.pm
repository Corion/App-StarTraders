package App::StarTraders::Planet;

use strict;
use Moose;

with 'App::StarTraders::Role::HasName';

has '+name' => ( default => 'unnamed planet' );

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);


no Moose;
__PACKAGE__->meta->make_immutable;

# Orbit this planet
sub enter {
    $_[0]->move_to($_[1]->target_system);
};

1;