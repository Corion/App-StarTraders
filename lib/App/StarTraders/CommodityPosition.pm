package App::StarTraders::CommodityPosition;
use strict;
use Moose;

has item => (
    is => 'rw',
    isa => 'App::StarTraders::Commodity',
    handles => {
        name => 'name',
        stackable => 'stackable',
    },
);

has quantity => (
    is => 'rw',
    isa => 'Int',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub weight {
    $_[0]->item->weight * $_[0]->quantity
};

=head2 C<< ->volume >>

This one goes to 11.

=cut

sub volume {
    $_[0]->item->volume * $_[0]->quantity
};

=head2 C<< ->adjust_by QUANTITY >>

Changes the quantity by the passed quantity (positive or negative).

A new CommodityPosition is
returned, representing the added/removed items.
The sign is the inverse of the quantity passed in.

=cut

sub adjust_by {
    my ($self,$quantity) = @_;
    $self->quantity( $self->quantity + $quantity );
    
    return (ref $self)->new( item => $self->item, quantity => -$quantity );
};

sub merge {
    my ($self,$other) = @_;
    my $taken = $self->adjust_by( $other->quantity );
    $other->adjust_by( $taken );
};

1;
