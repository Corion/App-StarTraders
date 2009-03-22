package App::StarTraders::Planet;
use strict;
use Moose;

#with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

sub build_name { 'unnamed planet' };
#has '+name' => ( default => 'unnamed planet' );

no Moose;
__PACKAGE__->meta->make_immutable;

*system = \&parent;

# How can we orbit this planet?
# This planet (or any place) should know about ships in/on it

sub can_release { 1 };
sub can_receive { 1 };

#sub receive {
#    my ($self,$ship) = @_;
#    print sprintf "Ship %s now orbits %s\n", $ship->name, $self->name;
#};

#sub release {
#    my ($self,$ship) = @_;
#    print sprintf "Ship %s leaves %s orbit\n", $ship->name, $self->name;
#};

1;
