package App::StarTraders::Wormhole;
use strict;
use Moose;

with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

has worm => (
    is => 'rw',
    isa => 'App::StarTraders::Worm',
);

# This should simply become an alias to &parent
# except that all constructors need to follow suit
has system => (
    is => 'ro',
    isa => 'App::StarTraders::StarSystem',
    weaken => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

# Should this be done by the build arg?
sub target_system { $_[0]->worm->tail($_[0])->system };

sub arrive { 
    my ($self,$ship) = @_;
    $self->system->ship_leave($ship);
    $self->worm->tail($self)->arrive($ship);
    #if ($self->target_system) {
        #$self->target_system->ship_enter($ship);
        #$ship->system($self->target_system);
    #};
};

sub depart { 
    my ($self,$ship) = @_;
};


1;