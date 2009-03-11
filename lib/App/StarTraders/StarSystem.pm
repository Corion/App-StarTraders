package App::StarTraders::StarSystem;
use strict;
use Moose;

with 'App::StarTraders::Role::HasName';
has '+name' => ( default => 'unnamed ship' );

has planets => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

has wormholes => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

has ships => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

no Moose;

sub add_planet {
    my $self = shift; 
    push @{ $self->{planets}}, @_
};

sub add_wormhole {
    my $self = shift; 
    push @{ $self->{wormholes}}, @_
};

sub ship_enter {
    my ($self, @ships) = @_;
    for (@ships) {
        print $_->name, " enters ", $self->name, "\n";
    };
    push @{ $self->{ships} }, @ships
};

sub ship_leave {
    my ($self, @ships) = @_;
    for (@ships) {
        print $_->name, " leaves ", $self->name, "\n";
    };
    my %ships = map { 0+$_ => 1 } @ships;
    my @newships = grep { !$ships{$_} } $self->ships;
    @{ $self->{ships} } = @newships;
};

1;