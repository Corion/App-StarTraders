package App::StarTraders::Ship;

use strict;
use Moose;

with 'App::StarTraders::Role::HasName';

has '+name' => ( default => 'unnamed ship' );

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);


no Moose;
__PACKAGE__->meta->make_immutable;

# Should this be done by the build arg?
sub move_to { 
    my ($self,$target) = @_;
    if ($self->system) {
        $self->system->ship_leave($self);
    };
    if ($target) {
        $target->ship_enter($self);
    };
    $_[0]->system($_[1])
};

# Enter a wormhole
sub enter {
    $_[0]->move_to($_[1]->target_system);
};

1;