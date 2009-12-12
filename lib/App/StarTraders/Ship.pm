package App::StarTraders::Ship;
use strict;
use Moose;

with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsContainer';

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weak_ref => 1,
);

has position => (
    is => 'rw',
    does => 'App::StarTraders::Role::IsPlace',
    weak_ref => 1,
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

=head2 Storage

=cut

sub pick_up {
    my ($self,$item,$quantity) = @_;
    my $p = $self->position;
    if ($p->can('capacity')) {
        #warn sprintf "Transferring %d %s from %s to %s", $quantity, $item->name, $p->name, $self->name;
        $p->transfer_to($self,$item,$quantity);
    };
};

sub drop {
    my ($self,$itemname,$amount) = @_;
    if ($self->position->can('capacity')) {
        $self->transfer_to($self->position,$itemname,$amount);
    };
};

sub swap {
    my ($self,$pickup_itemname,$pickup_amount, $drop_itemname, $drop_amount) = @_;
    if ($self->position->can('capacity')) {
        $self->transfer_to($self->position,$drop_itemname,$drop_amount);
        $self->position->transfer_to($self,$pickup_itemname,$pickup_amount);
    };
};

sub jettison {
    my ($self,$itemname,$amount) = @_;
    $amount ||= $self->quantity;
    $self->quantity( $self->quantity - $amount ); # poof
};

1;