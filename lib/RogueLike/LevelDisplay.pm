package RogueLike::LevelDisplay;
use Filter::signatures;
use Moo::Lax;

sub as_string( $self, $level, $state ) {
    # Draw the visible parts of the level
    my @d= @{ $level->map };

    # Draw the visible actors in the level
    for my $actor (@{ $state->actors }) {
        # Is the actor visible for the player?
        my $is_visible= 1;
        
        # Draw the actor
        my $pos= $actor->position;
        substr( $d[ $pos->[1] ], $pos->[0], 1)= $actor->avatar;
    };
    
    join( "\n", @d) . "\n"
}

# Also add the player (or viewpoint) as a parameter
# So we can have visibility
sub draw( $self, $level, $state ) {
    print $self->as_string( $level, $state );
}

package RogueLike::Terrain;
use Filter::signatures;
use feature 'signatures';
use Moo::Lax;

has map => (
    is => 'rw',
	default => sub { [ split /\n/, <<'Dungeon' ] },
##################################
#                             >  #
#########       #-######  ##  ####
#               + |              #
###             ###              #
#  <                             #
##################################
Dungeon
);

sub at( $self, $x, $y ) {
    if( ref $x ) {
        ($x,$y)= @$x;
    };
    return substr $self->map->[ $y ], $x, 1;
}

1;