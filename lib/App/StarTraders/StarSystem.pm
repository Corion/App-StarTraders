package App::StarTraders::StarSystem;
use strict;
use List::AllUtils qw(uniq);
use Moose;

with 'App::StarTraders::Role::HasName';

has [ qw[ planets wormholes other_places ]]=> (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

sub build_name { 'unnamed system' };

no Moose;

sub add_planet {
    my $self = shift;
    for (@_) { $_->parent($self) };
    push @{ $self->{planets}}, @_
};

sub add_wormhole {
    my $self = shift; 
    push @{ $self->{wormholes}}, @_
};

sub add_other_place {
    my $self = shift; 
    push @{ $self->{other_places}}, @_
};

sub ship_enter {
    my ($self, @ships) = @_;
    for (@ships) {
        print $_->name, " enters ", $self->name, "\n";
    };
};

sub ship_leave {
    my ($self, @ships) = @_;
    for (@ships) {
        print $_->name, " leaves ", $self->name, "\n";
    };
};

sub ships {
    my ($self) = @_;
    my @s = uniq map { $_->ships } $self->children
};

sub children {
    my $self = shift;
    $self->planets, $self->wormholes, $self->other_places
};

*reachable = \&children;

1;