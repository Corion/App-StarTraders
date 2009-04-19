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
    my $sol = $st->new_system(
            name => 'Sol',
            planets => [ planets( qw[Mercury Venus Earth Mars Jupiter Saturn Uranus Neptun Pluto]) ],
    );
    my $alpha = $st->new_system(
            name => 'Alpha Centauri',
    );
    my $other = $st->add_system( $self->random_system );

    $st->new_wormhole( $sol => $alpha );
    $st->new_wormhole( $alpha => $other );
    
    # now add a cluster of 20 more systems
    my $cl = $self->new_cluster(25);
    $st->new_wormhole($other,$cl);
    
    $st
};

=head2 C<< ->new_cluster COUNT >>

Creates a separate cluster of COUNT
systems. You need to connect
this cluster to the rest of the systems.

The subroutine returns the first
new system created, which
is connected to all other systems
in the cluster.

=cut

sub new_cluster {
    my ($self,$count) = @_;
    $count ||= 20;
    my $st = $self->spacetime;
    # now add a cluster of 20 more systems
    my $base = (() = $st->systems );
    
    my $result;
    
    for my $sys ($base..$base+$count) {
        my %holes = ($sys => 1);
        my $new = $self->random_system;
        $result ||= $new;
        
        # connect the system to some other random system:
        my $other = int rand($sys-$base);
        if ($base <= $other and $other != $sys and not $holes{$other}++) {
            $st->new_wormhole($new, $other);
        };

        # add some more random wormholes
        for my $r (1..5) {
            my $other = $base+int rand($sys-$base);
            if (rand 0.1 and not $holes{$other}++) {
                $st->new_wormhole($new, $other);
            }
        }
    };
    $result
}

1;