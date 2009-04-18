package App::StarTraders::Demiurge;
use strict;
use App::StarTraders::SpaceTime;
use App::StarTraders::Ship;
use App::StarTraders::Planet;

use Moose;

has spacetime => (
    is => 'ro',
    isa => 'App::StarTraders::SpaceTime',
    default => sub { App::StarTraders::SpaceTime->new() },
);

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

App::StarTraders::Demiurge - system creation

=head1 DESCRIPTION

This package provides the routines to create
random star systems together with the
Wormholes connecting them. It also
sets up the commodities, NPCs (if ever)
and so on.

It also stores the parameters for connectivity,
variation of planets, prevalence of factions,
loot etc.

=cut

sub random_system {
    my $self = shift;
    my $planets = int rand(10); 
    # planet distribution should become parametrizable
    # and also not be linearly distributed
    my $star = $self->spacetime->new_system();
    
    # uninhabited or uninteresting planets get just numbers,
    # the rest gets a name?
    my $system_name = $star->name;
    
    for (1..$planets) {
        my $name = join " ", $system_name, $_;
        $star->add_planet(
            App::StarTraders::Planet->new( name => $name )
        );
    };
    
    $star
}

sub planets {
    map { App::StarTraders::Planet->new( $_ ? (name => $_) : () ) } @_
};

sub new_universe {
    my $self = shift;
    my $st = $self->spacetime;

    # Create the "static" core system
    $st->new_system(
            name => 'Sol',
            planets => [ planets( qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]) ],
    );
    $st->new_system(
            name => 'Alpha Centauri',
    );
    $st->add_system( $self->random_system );

    $st->new_wormhole( 0,1 );
    $st->new_wormhole( 1,2 );
    
    # now add a cluster of 20 more systems
    my $base = (() = $st->systems ) -1;
    for my $sys (0..20) {
        my %holes = ($base+$sys => 1);
        $st->add_system( $self->random_system );
        # connect the system to some other random system:
        my $other = int rand($sys-1);
        if (0 <= $other and $other != $sys and not $holes{$base+$other}++) {
            $st->new_wormhole($base+$sys, $base + $other);
        };

        # add some more random wormholes
        for my $r (1..5) {
            my $other = int rand($sys-1);
            if (rand 0.1 and not $holes{$base+$other}++) {
                warn sprintf "%s -> %s\n", $base+$sys, $base+$other;
                $st->new_wormhole($base+$sys, $base + $other);
            }
        }
    };
    
    # Connect the "main" system with the other cluster
    $st->new_wormhole(2,3);
    
    $st
};

1;