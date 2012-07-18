package App::StarTraders::Role::IsContainer;
use strict;
use Moose::Role;
use List::Util qw(sum);
use App::StarTraders::CommodityPosition;

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

=head2 C<< ->capacity_used ITEM >>

Returns the used capacity of this container.

As long as we use integral units of item-capacity,
this will be an easy calculation.

=cut

sub capacity_used { sum map { $_->quantity } @{ $_[0]->items } };

=head2 C<< ->capacity_free ITEM >>

Returns the free capacity of this container.

As long as we use integral units of item-capacity,
this will be an easy calculation.

=cut

sub capacity_free { ($_[0]->capacity || 0) - $_[0]->capacity_used($_[1]) };

=head2 C<< ->normalize >>

Removes all items with a quantity of zero.

Also merges
all ItemPositions containing items of the same type
into one stack.

This will have to respect the C<stackable>
property of Items in the future.

=cut

sub normalize {
    my ($self) = @_;
    my $i = $self->items;
    my %stacks;
    my @result;
    
    for my $pos (@$i) {
        next unless ($pos->quantity);
        if ($pos->stackable) {
            if (exists $stacks{ $pos->item }) {
                $stacks{ $pos->item }->merge( $pos );
            } else {
                $stacks{ $pos->item } = $pos;
            };
        } else {
            push @result, $pos
        };
    };
    push @result, values %stacks;
    @$i = @result;
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
    $quantity ||= 0; # to avoid warnings
    
    my $contained = $self->find_item_position( $item );
    if ($contained) {
        my $pos = $contained->adjust_by(-$quantity);
        $self->normalize;
        return $pos
    };
};

sub transfer_to {
    my ($self,$target,$item,$quantity) = @_;
    
    my $pos = $self->withdraw( $item, $quantity );
    $target->deposit( $pos );
};

=head2 C<< $container->exchange( $other, [ $recv1, ...] , [ $pos2, ... ] ) >>

Atomically trades one set of commodities against
another set of commodities. No checks are made whether
the contents and exchange rate between the containers is acceptable
for each container.

=cut

sub exchange {
    my ($self, $target, $receivables, $outbound) = @_;
    
    # XXX It would be convenient to create a surrounding transaction, just
    #     in case picking up
    #     or dropping something fails. For that, picking up and dropping
    #     things should become functional instead of modifying state,
    #     and the modification should happen through a ->commit...
    
    # Check whether the transaction is acceptable for each container
    my @positions = ($receivables, $outbound);
    for my $c ($self,$target) {
        if ($c->can('exchange_acceptable')) {
            my @reasons = $c->transaction_acceptable(@positions);
            if (@reasons) {
                print sprintf "Transaction rejected by %s: %s",
                    $c->name, join " and ", @reasons;
            }
        }
        @positions = reverse @positions;
    }
    # Withdraw all commodities from each container
    
    my (@bundles) = ([],[]);
    for my $c ($self,$target) {
        push @{$bundles[0]}, map { $c->withdraw( $_ )} @{$positions[0]};
        @bundles = reverse @bundles;
        @positions = reverse @positions;
    };
    
    # Deposit the commodities in the opposite container
    for my $c ($self,$target) {
        for my $p (@{$bundles[1]}) {
            $c->deposit( $p )
        };
        @bundles = reverse @bundles;
        @positions = reverse @positions;
    };
}

sub purge {
    my ($self) = @_;
    
    $self->items([]); # poof
};

1;