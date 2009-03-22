package App::StarTraders::WormholeExit;
use strict;
use Moose;

with 'App::StarTraders::Role::IsPlace';

has worm => (
    is => 'rw',
    isa => 'App::StarTraders::Worm',
);

# This should simply become an alias to &parent
has system => (
    is => 'ro',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

has '+is_visible' => ( default => 0 );

sub build_name { 'a wormhole exit' };

after 'arrive' => sub {
    my ($self,$ship) = @_;
    print $ship->name . " arrives in " . $self->name . "\n";
    if ($self->system) {
        $self->system->ship_enter($ship);
        $ship->system($self->system);
        $ship->position($self);
    };
};

no Moose;
__PACKAGE__->meta->make_immutable;

# Should this be done by the build arg?
sub source_system { $_[0]->worm->tail($_[0])->system };

1;