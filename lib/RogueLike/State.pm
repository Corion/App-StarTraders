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