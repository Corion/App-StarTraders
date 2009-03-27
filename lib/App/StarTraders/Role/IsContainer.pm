package App::StarTraders::Role::IsContainer;
use strict;
use Moose::Role;

has capacity => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# This will belong to IsItemStack (or ItemStack?)
# A container contains multiple ItemStacks

has quantity => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has item => (
    is => 'rw',
    isa => 'Str',
    default => 'Nothing',
);

=head2 C<< ->capacity_used >>

Returns the used capacity of this container.

As long as we use integral units of item-capacity,
this will be an easy calculation.

=cut

sub capacity_used { $_[0]->quantity };

sub capacity_free { $_[0]->capacity - $_[0]->capacity_used };

sub transfer {
    my ($self,$target,$item,$amount);
    $target->quantity( $target->quantity-$amount );
    $self->item($item);
    $self->quantity($self->quantity+$amount);
};

sub purge {
    my ($self) = @_;
    $self->quantity(0);
    $self->item(undef);
};

1;