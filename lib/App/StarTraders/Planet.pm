package App::StarTraders::Planet;
use strict;
use Moose;

with 'App::StarTraders::Role::IsPlace';
with 'App::StarTraders::Role::IsContainer'; # this should later be(come) a building on the planet

no Moose;
__PACKAGE__->meta->make_immutable;

*system = \&parent;

use vars '@digrams';

@digrams = qw(
.. LE XE GE ZA CE BI SO
US ES AR MA IN DI RE A.
ER AT EN BE RA LA VE TI
ED OR QU AN TE IS RI ON
);

sub build_name {
    my $length = rand() > 0.5 ? 3 : 4;
    ucfirst lc join "", map { tr!.!!d; $_ } @digrams[ map { rand @digrams } 1..$length ];
};

1;
