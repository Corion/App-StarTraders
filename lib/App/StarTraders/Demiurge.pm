package App::StarTraders::Demiurge;
use strict;
use App::StarTraders::SpaceTime;
use App::StarTraders::Ship;
use App::StarTraders::Planet;
use App::StarTraders::Demiurge::CommodityPresets;
use Carp qw(croak);

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
    my $star = $self->spacetime->new_system(@_);
    
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
    
    # Create the matter in our universe
    App::StarTraders::Demiurge::CommodityPresets->create_commodities(
        spacetime => $st
    );

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

# XXX Make the factions configurable
my @factions = qw(
    Weyland-Yutami
    Empire
    Federation
    Church
);

sub new_cluster {
    my ($self,$count,$faction) = @_;
    $count ||= 20;
    $faction ||= $factions[ rand @factions ];
    my $st = $self->spacetime;
    # now add a cluster of 20 more systems
    my $base = (() = $st->systems );
    
    my $result;
    
    for my $sys ($base..$base+$count) {
        my %holes = ($sys => 1);
        my $new = $self->random_system( faction => $faction );
        $result ||= $new;
        
        # connect the system to some other random system:
        my $other = int rand($sys-$base);
        if ($base <= $other and $other != $sys and not $holes{$other}++) {
            $st->new_wormhole($new, $other);
        };
        
        # sprinkle some commodities into the system
        $self->deposit_random_commodity( system => $new, maximum => 200 );

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

=head2 C<< find_random_planet >>

Returns a random planet, without any further
restrictions

It would be nice to have limits on the environment,
gravity and so on later, which likely
involves creating a specification "language" for such searches.

Also, the Demiurge would potentially need to I<create> such a
planet if none is found to satisfy the completion
of quests that need such planets.

=cut

sub find_random_planet {
    my ($self, @eligible_planets) = @_;
    
    if (! @eligible_planets) {
        @eligible_planets = map { $_->planets } $self->spacetime->systems;
    };
    $eligible_planets[ rand @eligible_planets ]
};

sub find_random_commodity {
    my ($self, @commodities) = @_;
    
    if (! @commodities) { 
        @commodities = values %{ $self->spacetime->commodities };
    };
    croak "No commodities configured"
        unless @commodities;
    $commodities[ rand @commodities ]
};

sub random_amount {
    my ($self,$planet,$commodity,$maxval) = @_;
    return int rand $maxval
}

sub deposit_random_commodity {
    my ($self,%options) = @_;
    my $planet = delete $options { planet };
    my $system = delete $options { system };
    my $amount = delete $options{ amount };
    my $commodity = delete $options{ commodity };
    my $maximum_value = delete $options{ maximum };

    my @planets;    
    if ($system) {
        @planets = $system->planets;
    };
    $planet        ||= $self->find_random_planet(@planets);
    $commodity     ||= $self->find_random_commodity;
    $maximum_value ||= 100;
    $amount        ||= $self->random_amount($planet,$commodity,$maximum_value);
    warn sprintf "Depositing %d %s on %s",
        $amount, $commodity->name, $planet->name;

    # XXX We should log here that (and why) we're creating new matter
    $planet->deposit( $commodity => $amount );
};

1;