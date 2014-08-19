package RogueLike::Effect;
use strict;
use Filter::signatures;
use Moo;

# Time until this effect expires
has 'duration' => (
    is => 'ro',
    default => 0,
);

# The factors or terms that change the actor
has 'attributes' => (
    is => 'ro',
    default => sub { {} },
);

has name => (
    is => 'ro',
    default => '(a) effect',
);

1;