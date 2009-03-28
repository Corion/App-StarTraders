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

sub find_item_position {
    my ($self,$item) = @_;
    my @res = grep { $_->item == $item } @{ $self->items };
    return wantarray ? @res : $res[0]
};

=head2 C<< ->deposit $position >>

=head2 C<< ->deposit $item, $quantity >>

Places the position in the container.

=cut

sub deposit {
    my ($self,$item,$quantity) = @_;
    
    my $pos = $item;
    if (@_ == 3) {
        $pos = App::StarTraders::CommodityPosition->new( item => $item, quantity => $quantity );
    };
    push @{ $self->items }, $pos;
    $self->normalize;
};

=head2 C<< ->withdraw $item, $quantity >>

Removes C<$quantity> items from the container.
Returns the CommodityPosition representing the items.

=cut

sub withdraw {
    my ($self,$item,$quantity) = @_;
    
    my $contained = $self->find_item_position( $item );
    if ($contained) {
        my $pos = $contained->adjust_by(-$quantity);
        $self->normalize;
    };
};

sub transfer_to {
    my ($self,$target,$item,$quantity) = @_;
    
    my $pos = $self->withdraw( $item, $quantity );
    $target->deposit( $pos );
};

sub purge {
    my ($self) = @_;
    
    $self->items([]); # poof
};

1;