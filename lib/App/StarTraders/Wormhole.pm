package App::StarTraders::Wormhole;
use strict;
use Moose;

has worm => (
    is => 'rw',
    isa => 'App::StarTraders::Worm',
);

has system => (
    is => 'ro',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

# Should this be done by the build arg?
sub target_system { $_[0]->worm->tail($_[0])->system };

1;