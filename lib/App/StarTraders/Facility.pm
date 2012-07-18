package App::StarTraders::Facility;
use strict;
use App::StarTraders::CommodityPosition;
use Moose;

# Maybe this should become a (parametrized) role,
# indicating what is available for trading

with 'App::StarTraders::Role::IsPlace';
# at least until I figure out whether it's floating in space or fixed on a planet
with 'App::StarTraders::Role::IsContainer';

sub build_name { 'unnamed facility' };

no Moose;
__PACKAGE__->meta->make_immutable;

sub exchange_acceptable {
    ('No,no,no - trading is not implemented yet')
}

=head1 NAME

App::StarTraders::Facility

=head 2 DESCRIPTION

=over 4

=item *

Provides a means to exchange items

=item *

Has an exchange rate depending on its surrounding needs (planetary/system)

=item *

Replenishes certain items over time

=item *

Only accepts certain items in trade

=back

=head2 INSTANCES

Potential instances are

=over 4

=item *

Trading post

Simple buying and selling of items

=item *

Mine

Only sells one kind of item, but will
buy up various other items

=item *

Factory

Sells one kind of item, but will buy a limited
set of other items needed to "produce" that one kind
of item

=back

=cut

1;