package App::StarTraders::Planet;

use strict;
use Moose;

#with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

has '+name' => ( default => 'unnamed planet' );

# What about "position", which is a Place in a StarSystem
# This should be(come) a role!?
# Shouldn't ->system() become ->parent() ?
has system => (
    is => 'rw',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

# How can we orbit this planet?

1;