package RogueLike::Terrain;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use RogueLike::Fixture;

has name => (
    is => 'ro',
    default => 'The dungeons',
);

has map => (
    is => 'rw',
	default => sub { [ split /\n/, <<'Dungeon' ] },
##################################
#                             >  #
#########       #+######  ##  ####
#               + +              #
###             ###              #
#  <                             #
##################################
Dungeon
);

=head2 C<< ->fixtures >>

Contains the fixtures of the level.

Fixtures are

Doors that can open/close.

Drawbridges that can open/close.

Stairs that lead up/down.

Level portals that lead to different parts of the world

=cut

has fixtures => (
    is => 'rw',
    default => sub { [] },
);

# Should return a tile, not a char
sub at( $self, $x, $y ) {
    if( ref $x ) {
        ($x,$y)= @$x;
    };
    return substr $self->map->[ $y ], $x, 1;
}

sub tile_at( $self, $x, $y ) {
    my( $res )= grep { my $p=$_->position; $x == $p->[0] and $y == $p->[1] } @{ $self->fixtures };
    if( ! $res ) {
        $res= RogueLike::Fixture::GenericTile->new(
            position => [$x,$y],
            avatar => $self->at( $x, $y ),
        );
    };
    $res
}

# The extent of the map, used for rendering
has dimensions => (
    is => 'rw',
);

sub BUILD( $self ) {
    my $h= $#{ $self->map };
    my $w=0;
    for( @{ $self->map }) {
        $w= length($_) > $w ? length($_): $w;
    };
    $self->dimensions( [ $w, $h ]);
    $self->parse_map();
}

# Construct ->fixtures from a map
sub parse_map( $self ) {
    my $d = $self->dimensions;
    my $map= $self->map;
    my @fixtures;
    for my $y ( 0..$d->[1] ) {
        for my $x (0..$d->[0]) {
            # Recognize special fixtures
            my $f= $self->at( $x, $y );
            if( $f =~ /[\-\+\|]/ ) { # currently we only allow "+" as door indicator... No open doors
                
                my $orientation;
                if( '+' eq $f ) {
                    # Find space left/right to the door
                    # If it's empty, it's a "-"
                    # otherwise, it's a "|"
                    my $left_of=  $self->at( $x-1, $y );
                    if( $left_of =~ / /) {
                        $orientation= '-';
                    } else {
                        $orientation= '|';
                    };
                } else {
                    $orientation= $f;
                };
                
                push @fixtures, RogueLike::Fixture::Door->new(
                    position => [$x,$y],
                    open_state => ($f ne '+'),
                    orientation => $orientation,
                );

            } elsif( $f =~ /[<>]/ ) {
                # a staircase up/down
                
                push @fixtures, RogueLike::Fixture::Staircase->new(
                    position => [$x,$y],
                    direction => $f,
                    target_level => '1', # well ...
                );
            };
        };
    };
    $self->fixtures( \@fixtures );
}

1;