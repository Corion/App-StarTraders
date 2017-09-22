package RogueLike::Item;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
# http://journal.stuffwithstuff.com/2014/07/05/dropping-loot/

use vars qw(%walkable);
%walkable= (
    ' ' => 1,
	'-' => 1,
	'|' => 1,
);

has hierarchy => (
    is => 'ro',
	# equipment/trinket/gem/PrettyStone
);

has name => (
    is => 'rw',
	# "My first pretty glass shard"
);

has appearance => (
    is => 'rw',
	default => 'a generic item',
	# "a glass shard"
);

has score_points => (
    is => 'ro',
	default => 0, # most stuff is just useless
);

has weight => (
    is => 'ro',
	default => 1,
);

has flags => (
    is => 'ro',
	default => sub { {} },
);

# Every item is in a container
# If there is "no" container, then it's in the "NoContainer" class
has container => (
    is => 'rw',
    default => sub { },
);

sub is( $self, $item ) {
    $self->flags->{ $item }
};

# Delegates to the container
sub position( $self ) {
    $self->container->position;
}

package Item::WeaponRole;
use feature 'signatures';
use Moo::Role;

has damage => (
    is => 'ro',
	default => '1d1', # very low damage ;)
);

has attack_mode => (
    is => 'ro',
	default => 'hit(s)', # You hit / it hits
);

package Item::ClothingRole;
use feature 'signatures';
use Moo::Role;

# ???
