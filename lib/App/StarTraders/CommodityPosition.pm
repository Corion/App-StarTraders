package App::StarTraders::CommodityPosition;
use strict;
use Moose;

has item => (
    is => 'rw',
    isa => 'App::StarTraders::Commodity',
);

has quantity => (
    is => 'rw',
    isa => 'Int',
);

has weight => (
    is => 'rw',
    isa => 'Int',
);

has volume => (
    is => 'rw',
    isa => 'Int',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub weight {
    $_[0]->item->weight * $_[0]->quantity
};

sub volume {
    $_[0]->item->volume * $_[0]->quantity
};

1;
