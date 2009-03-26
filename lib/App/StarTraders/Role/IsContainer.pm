package App::StarTraders::Role::IsContainer;
use strict;
use Moose::Role;

has capacity => (
    is => 'rw',
    isa => 'Integer',
    default => 0,
);

# This will belong to IsItemStack (or ItemStack?)
# A container contains multiple ItemStacks

has quantity => (
    is => 'rw',
    isa => 'Integer',
    default => 0,
);

has item => (
    is => 'rw',
    isa => 'String',
    default => 'Nothing',
);

=head2 C<< ->capacity_used >>

Returns the used capacity of this container.

As long as we use integral units of item-capacity,
this will be an easy calculation.

=cut

sub capacity_used { $_[0]->quantity };

sub capacity_free { $_[0]->capacity - $_[0]->capacity_used };

1;