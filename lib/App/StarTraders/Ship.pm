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
sub move_to { 
    my ($self,$target) = @_;
    my $can_depart = ! $self->position || $self->position->can_depart($self);
    my $can_arrive = ! $target || $target->can_arrive($self);
    if ($can_depart and $can_arrive) {
        if ($self->position) { $self->position->depart($self) };
        if ($target) { $target->arrive($self) };
    } else {
        print sprintf "Invalid move ($can_depart->$can_arrive): Cannot move %s from %s to %s.\n",
                      $self->name, $self->position->name, $target->name;
    };
};

# Enter a wormhole
sub enter {
    $_[0]->move_to($_[1]->target_system);
};

1;