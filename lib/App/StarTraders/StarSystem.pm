package App::StarTraders::StarSystem;
use strict;
use Moose;

has name => (
    is => 'ro',
    isa => 'Str',
    default => 'unnamed star',
);

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

no Moose;

sub add_planet {
    my $self = shift; 
    push @{ $self->{planets}}, @_
};

sub add_wormhole {
    my $self = shift; 
    push @{ $self->{wormholes}}, @_
};

1;