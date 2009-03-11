package App::StarTraders::Ship;

use strict;
use Moose;

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

has name => (
    is => 'rw',
    isa => 'Str',
    default => 'unnamed ship',
);

no Moose;

# Should this be done by the build arg?
sub move_to { $_[0]->system($_[1]) };

# Enter a wormhole
sub enter {
    $_[0]->move_to($_[1]->target_system);
};

1;