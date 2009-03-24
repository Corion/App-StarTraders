package App::StarTraders::Role::IsContainer;
use strict;
use Moose::Role;

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

1;