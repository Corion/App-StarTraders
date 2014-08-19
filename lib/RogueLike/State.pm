package RogueLike::State;
use Filter::signatures;
use Moo;

use RogueLike::Fixture;

has terrain => (
    is => 'ro',
    default => sub { RogueLike::Terrain->new() },
);

has actors => (
    is => 'rw',
    default => sub { [] },
);

# A bit dumb still, but...
sub can_enter( $self, $actor, $position ) {
    my $barrier_at= $self->barrier_at( $position );
    
    my $can_enter=    $barrier_at->avatar =~ / /
                   || $barrier_at->avatar =~ /[-|]/  # open door
                   ;
    print sprintf "(%d,%d) Barrier is ' ' (%s)\n", @$position, $barrier_at->avatar, $can_enter;
    $can_enter;
}

sub add_actor( $self, @actors ) {
    push @{ $self->actors }, @actors;
    
    $self->rebuild_actors;
}

# Assumes that the first actor has just spent energy (or not)
# This should become a priority queue for speed
sub rebuild_actors( $self, $actor ) {
    my $actors= $self->actors;
    
    warn "Rebuilding actor order";

    # Put the actor that just acted at the end of its (new) priority queue
    if( $actor ) {
        @$actors= grep { $_ != $actor } @$actors;
        push @$actors, $actor;
    };
    
    # Well, a real priority queue insert would be better, but...
    @$actors= sort { $b->energy <=> $a->energy } (@{ $actors });
    
    $actors
}

# Return all actors with enough enery, in the "preferred" order
sub ready_to_act( $self ) {
}

# A BSP / quadtree, or just brute force?
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
sub barrier_at( $self, $x, $y ) {
    if( ref $x ) {
        ($x,$y)= @$x;
    };

    my $actor= $self->actor_at( $x, $y );

    return $actor
        if $actor;
    
    # Otherwise, we have a tile
    $self->terrain->tile_at($x,$y);
}

# Parse the current level for fixtures?!
sub set_level( $self, $level ) {
}

1;