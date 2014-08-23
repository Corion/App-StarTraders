package RogueLike::Fixture;
use strict;
use Filter::signatures;
use Moo::Lax;

has 'position' => (
    is => 'rw',
    default => sub { [0,0] },
);

has 'name' => (
    is => 'rw',
    default => sub { 'unnamed fixture' },
);

has is_openable => (
    is => 'ro',
    default => 0,
);

has is_forceable => (
    is => 'ro',
    default => 0,
);

sub avatar($self) {
    '.'
}

# A tile on the floor should not _be_ a Door / Staircase
# but it should _have_ one!

package RogueLike::Fixture::GenericTile;
use strict;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Fixture';

has 'name' => (
    is => 'rw',
    default => sub { '(the) floor' },
);

has 'type' => (
    is => 'ro',
    default => sub { {} },
);

has avatar => (
    is => 'ro',
    default => ' ',
);

package RogueLike::Fixture::Door;
use strict;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Fixture';

sub BUILDARGS( $self, %options ) {
    $options{ type } ||= {};
    $options{ type }->{ openable } //= 1;
    \%options
}

has 'position' => (
    is => 'rw',
    default => sub { [0,0] },
);

has 'orientation' => (
    is => 'ro',
    default => sub { '-' },
);

has 'name' => (
    is => 'rw',
    default => sub { '(a) door' },
);

has is_openable => (
    is => 'ro',
    default => 1,
);

has is_forceable => (
    is => 'ro',
    default => 1,
);

has 'open_state' => (
    is => 'rw',
    default => sub { 0 }, # for some, all doors are shut
);

sub avatar($self) {
    if( $self->open_state ) {
        $self->orientation
    } else {
        '+'
    };
}

package RogueLike::Fixture::Staircase;
use strict;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Fixture';

sub BUILDARGS( $self, %options ) {
    $options{ type } ||= {};
    $options{ type }->{ level_portal } //= 1; # Do we want that?
    \%options
}

has 'direction' => (
    is => 'ro',
    default => sub { '>' },
);

has 'name' => (
    is => 'rw',
    default => sub { '(a) staircase' },
);

sub avatar($self) {
    $self->direction
}

1;