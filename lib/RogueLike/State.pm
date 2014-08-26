package RogueLike::State;
use Filter::signatures;
use Moo::Lax;

# The "current" level
# Not sure how to handle multiple actors being in
# various levels.
#has terrain => (
#    is => 'ro',
#    default => sub { RogueLike::Terrain->new(
#        depth => 1,
#    ) },
#);

use RogueLike::DungeonLevel;

sub BUILDARGS( $self, %options ) {
    $options{ levels } //= [
        RogueLike::DungeonLevel->new(
            depth => 1,
        ),
    ];
    $options{ current_level } //= $options{ levels }->[ 0 ];
    return \%options
}

has levels => (
    is => 'ro',
);

# A temporary hack to store "the one" level
# In the future there will not be only one active level
has current_level => (
    is => 'rw',
);

# Should we structure the actors by terrain?
# We only use the "current" terrain/level
sub actors( $self ) {
    $self->current_level->actors
};

# A bit dumb still, but...
sub can_enter_tile( $self, $actor, $position ) {
    my $barrier_at= $self->barrier_at( $position );
    
    my $can_enter=    $barrier_at->avatar =~ / /
                   || $barrier_at->avatar =~ /[-|]/  # open door
                   || $barrier_at->avatar =~ /[<>]/  # staircase
                   # Should also handle portals, holes
                   ;
    #print sprintf "(%d,%d) Barrier is ' ' (%s)\n", @$position, $barrier_at->avatar, $can_enter;
    $can_enter;
};

# Create a new level
sub get_level( $self, $depth ) {
    return RogueLike::DungeonLevel->new(
        depth => $depth
    );
};

sub add_level( $self, $level ) {
    push @{ $self->levels }, $level;
}

# Implicitly only works on the current level
sub add_actor( $self, @actors ) {
    push @{ $self->actors }, @actors;
    
    $self->current_level->add_actor( @actors );
    
    $self->rebuild_actors;
};

# Assumes that the first actor has just spent energy (or not)
# This should become a priority queue for speed
sub rebuild_actors( $self, $actor ) {
    my $actors= $self->actors;
    
    #warn "Rebuilding actor order";

    # Put the actor that just acted at the end of its (new) priority queue
    if( $actor ) {
        @$actors= grep { $_ != $actor } @$actors;
        push @$actors, $actor;
    };
    
    # Well, a real priority queue insert would be better, but...
    @$actors= sort { $b->energy <=> $a->energy } (@{ $actors });
    
    $actors
}

# Return all actors with enough energy, in the "preferred" order
sub ready_to_act( $self ) {
}

# A BSP / quadtree, or just brute force?
# Implicitly only on the current level?!
# This should go into ::DungeonLevel
sub actor_at( $self, $x, $y ) {
    if( ref $x ) {
        ($x,$y)= @$x;
    };
    (grep {
        my $p= $_->position;
            $p->[0] == $x
        and $p->[1] == $y
    } @{ $self->actors })[0]
}

# A BSP / quadtree, or just brute force?
# How do we incorporate the "current level" here?!
# This should go into ::DungeonLevel
sub barrier_at( $self, $x, $y ) {
    if( ref $x ) {
        ($x,$y)= @$x;
    };

    my $actor= $self->actor_at( $x, $y );

    return $actor
        if $actor;
    
    # Otherwise, we have a tile
    $self->current_level->terrain->tile_at($x,$y);
}

# Parse the current level for fixtures?!
sub set_level( $self, $level ) {
}

1;