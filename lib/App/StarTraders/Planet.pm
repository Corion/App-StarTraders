package App::StarTraders::Planet;
use strict;
use Moose;

with 'App::StarTraders::Role::IsPlace';
with 'App::StarTraders::Role::IsContainer'; # this should later be(come) a building on the planet

no Moose;
__PACKAGE__->meta->make_immutable;

*system = \&parent;

sub build_name {
    'unnamed planet'
}
1;
