package RogueLike::State;
use Filter::signatures;
use Moo;

has terrain => (
    is => 'ro',
    default => sub { RogueLike::Terrain->new() },
);

has 'actors' => (
    is => 'rw',
    default => sub { [] },
);

sub can_enter( $self, $actor, $position ) {
    my $char_at= $self->terrain->at($position);
    $char_at =~ / /
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

1;