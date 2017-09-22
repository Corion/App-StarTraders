package RogueLike::Effect;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# Time until this effect expires
# Should this better be the timestamp when the effect expires?
# This would make it easier when items are not in view

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