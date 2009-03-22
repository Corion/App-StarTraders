package App::StarTraders::Ship;

use strict;
use Moose;

with 'App::StarTraders::Role::HasName';

#has '+name' => ( default => 'unnamed ship' );

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

has position => (
    is => 'rw',
    does => 'App::StarTraders::Role::IsPlace',
    weaken => 1,
);

sub build_name { 'unnamed ship' };

no Moose;
__PACKAGE__->meta->make_immutable;

# This currently only allows to move between systems
# not landing on/orbiting a planet
sub move_to { 
    my ($self,$target) = @_;
    if ($self->position && $self->position->can_depart($self)) {
        $self->position->depart($self);
    };
    $target->arrive($self);
};

# Enter a wormhole
sub enter {
    $_[0]->move_to($_[1]->target_system);
};

1;