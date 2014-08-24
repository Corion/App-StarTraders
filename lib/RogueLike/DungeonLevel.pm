package RogueLike::DungeonLevel;
use Filter::signatures;
use feature 'signatures';
use Moo::Lax;

use RogueLike::Terrain;

has terrain => (
    is => 'ro',
    default => sub { RogueLike::Terrain->new() },
);

has actors => (
    is => 'ro',
    default => sub { [] },
);

has depth => (
    is => 'ro',
);

# Distance/hardness
has distance => (
    is => 'ro',
);

sub name( $self ) {
    $self->terrain->name
}

sub add_actor( $self, @actors ) {
    for( @actors ) {
        $_->set_dungeon_level( $self );
    };
    push @{ $self->actors }, @actors
    # Sort the actors for this level...
}

sub remove_actor( $self, @actors ) {
    my %remove= map { 0+$_ => 1 } @actors;
    for( @actors ) {
        $_->set_dungeon_level( undef );
    };
    @{ $self->actors }= grep { !$remove{ 0+$_ } } @{ $self->actors };
}

1;