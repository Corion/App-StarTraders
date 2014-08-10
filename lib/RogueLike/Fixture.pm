package RogueLike::Fixture;
use strict;
use Filter::signatures;
use Moo;

has 'position' => (
    is => 'rw',
    default => sub { [0,0] },
);

has 'name' => (
    is => 'rw',
    default => sub { 'unnamed fixture' },
);

has 'type' => (
    is => 'ro',
    default => sub { {} },
);

sub avatar($self) {
    '.'
}

package RogueLike::Fixture::GenericTile;
use strict;
use Filter::signatures;
use Moo;

has 'position' => (
    is => 'rw',
    default => sub { [0,0] },
);

has 'name' => (
    is => 'rw',
    default => sub { 'floor' },
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
use Moo;

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

has 'open_state' => (
    is => 'rw',
    default => sub { 0 }, # for some, all doors are shut
);

sub avatar($self) {
    warn "Door: " . $self->open_state;
    if( $self->open_state ) {
        $self->orientation
    } else {
        '+'
    };
}

1;