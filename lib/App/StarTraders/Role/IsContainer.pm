package App::StarTraders::Role::IsContainer;
use strict;
use Moose::Role;
use List::Util qw(sum);

has capacity => (
    is => 'rw',
    isa => 'Int',
    default => 10000,
);

# This will belong to IsItemStack (or ItemStack?)
# A container contains multiple ItemStacks

has items => (
    is => 'rw',
    isa => 'ArrayRef[App::StarTraders::Role::CommodityPosition]',
    default => sub { [] },
);

=head2 C<< ->capacity_used >>

Returns the used capacity of this container.

As long as we use integral units of item-capacity,
this will be an easy calculation.

=cut

sub capacity_used { sum map { $_->quantity } @{ $_[0]->items } };

sub capacity_free { $_[0]->capacity - $_[0]->capacity_used };

=head2 C<< ->normalize >>

Removes all items with a quantity of zero.

Also should merge
all ItemPositions containing items of the same type
into one stack. This will have to respect the C<stackable>
property of Items.

=cut

sub normalize {
    my ($self) = @_;
    $self->items( [ grep { $_->quantity } @{ $self->items } ]);
    # (re)stack items that are stackable
};

sub deposit {
    my ($self,$item,$amount) = @_;
    my $pos = App::StarTraders::CommodityPosition->new( item => $item, quantity => $amount );
    push @{ $self->items }, $pos;
    $self->normalize;
};

=head2 C<< ->withdraw $item, $quantity >>

Removes C<$quantity> items from the container.
Returns the CommodityPosition representing the items.

=cut

sub withdraw {
    my ($self,$item,$quantity) = @_;
    my $pos = App::StarTraders::CommodityPosition->new( item => $item, quantity => $quantity );
    $self->normalize;
};

sub transfer_to {
    my ($self,$target,$item,$amount) = @_;
    $target->quantity( $target->quantity+$amount );
    $target->item($item);
    $self->quantity($self->quantity-$amount);
};

sub purge {
    my ($self) = @_;
    $self->quantity(0);
    $self->item(undef);
};

1;