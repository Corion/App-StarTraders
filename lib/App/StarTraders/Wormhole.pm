package App::StarTraders::Wormhole;
use strict;
use Moose;

with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

has worm => (
    is => 'rw',
    isa => 'App::StarTraders::Worm',
);

=head1 Musings

This current implementation does not lead
itself to convenient graph analysis for
automated path planning. Ideally, the ship
itself would actively move between the places
that are reachable in one step, instead of
the wormhole entrance and exit being magic
portals between the two solar systems.

That implementation postponed until A* and AI
need to be implemented to faciliate automated
navigation between systems.

=cut

# This should simply become an alias to &parent
# except that all constructors need to follow suit
has system => (
    is => 'ro',
    isa => 'App::StarTraders::StarSystem',
    weak_ref => 1,
);

my $count = 1;
sub build_name { 'a unnamed wormhole entry #' . $count++ };

no Moose;
__PACKAGE__->meta->make_immutable;

# Should this be done by the build arg?
sub target_system { $_[0]->worm->tail($_[0])->system };

sub arrive { 
    my ($self,$ship) = @_;
    $self->system->ship_leave($ship);
    $self->worm->tail($self)->arrive($ship);
};

1;