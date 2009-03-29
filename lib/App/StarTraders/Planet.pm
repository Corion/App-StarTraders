package App::StarTraders::Planet;
use strict;
use Moose;

#with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';
with 'App::StarTraders::Role::IsContainer'; # this should later be(come) a building on the planet

sub build_name { 'unnamed planet' };
#has '+name' => ( default => 'unnamed planet' );

no Moose;
__PACKAGE__->meta->make_immutable;

*system = \&parent;

1;
