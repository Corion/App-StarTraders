package RogueLike::LevelDisplay;
use Filter::signatures;
use Moo::Lax;

sub overdraw( $self, $map, $items ) {
    # Draw the visible actors in the level
    for my $item (@{ $items }) {
        # Is the item visible for the player?
        my $is_visible= 1;
        
        # Draw the item
        my $pos= $item->position;
        #use Data::Dumper;
        #warn Dumper $pos;
        #warn Dumper $map;
        print sprintf "(%d,%d) %s: '%s'\n", @$pos, $item->name, $item->avatar;
        my $avatar= $item->avatar
            or die "No avatar for " . Dumper $item;
        substr( $map->[ $pos->[1] ], $pos->[0], 1)= $item->avatar;
    };
}

sub as_string( $self, $state ) {
    # Draw the visible parts of the level
    my @d= @{ $state->terrain->map };

use Data::Dumper;
warn Dumper \@d;
warn Dumper $_
    for @{ $state->terrain->fixtures };
    $self->overdraw( \@d, $state->terrain->fixtures );
warn Dumper \@d;
    $self->overdraw( \@d, $state->actors );
    
    join( "\n", @d) . "\n"
}

# Also add the player (or viewpoint) as a parameter
# So we can have visibility
sub draw( $self, $state ) {
    print $self->as_string( $state );
}

package RogueLike::Terrain;
use Filter::signatures;
use feature 'signatures';
use Moo::Lax;

use RogueLike::Fixture;

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