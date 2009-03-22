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

sub can_release { 1 };
sub can_receive { 1 };

sub receive {
    my ($self,$ship) = @_;
    print sprintf "Ship %s now orbits %s\n", $ship->name, $self->name;
};

sub release {
    my ($self,$ship) = @_;
    print sprintf "Ship %s leaves %s orbit\n", $ship->name, $self->name;
};

1;
