package App::StarTraders::CommodityPosition;
use strict;
use Moose;

has item => (
    is => 'rw',
    isa => 'App::StarTraders::Commodity',
);

has quantity => (
    is => 'rw',
    isa => 'Int',
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

If the quantity is negative, a new CommodityPosition is
returned, representing the removed items.

=cut

sub adjust_by {
    my ($self,$quantity) = @_;
    $self->quantity( $self->quantity + $quantity );
    
    if ($quantity < 0) {
        return (ref $self)->new( item => $self->item, quantity => -$quantity );
    }; 
};

1;
