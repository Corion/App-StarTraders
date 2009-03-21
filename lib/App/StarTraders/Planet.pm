package App::StarTraders::Planet;
use strict;
use Moose;

with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

has '+name' => ( default => 'unnamed planet' );

no Moose;
__PACKAGE__->meta->make_immutable;

*system = \&parent;

# How can we orbit this planet?

1;
