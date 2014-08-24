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
        my $avatar= $item->avatar
            or die "No avatar for " . Dumper $item;
        substr( $map->[ $pos->[1] ], $pos->[0], 1)= $item->avatar;
    };
}

sub as_string( $self, $state, $dungeon_level ) {
    # Draw the visible parts of the level
    my @d= @{ $dungeon_level->terrain->map };

    $self->overdraw( \@d, $dungeon_level->terrain->fixtures );
    $self->overdraw( \@d, $dungeon_level->actors );
    
    join( "\n", @d) . "\n"
}

# Also add the player (or viewpoint) as a parameter
# So we can have visibility
sub draw( $self, $state, $dungeon_level ) {
    print $self->as_string( $state, $dungeon_level );
}

1;