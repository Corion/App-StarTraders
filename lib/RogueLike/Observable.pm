package RogueLike::Observable;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# This is an observable change, to be seen by actors
# Player actors will likely get this displayed to them in a console
# AI actors will maybe wake up due to it happening in their vincinity

# Maybe this should be named "Event", but maybe an "Event" is something
# larger than "x hits y"

# Position updates do not propagate through this mechanism
# (or should they?!)

has 'type' => (
    is => 'ro',
    default => undef,
);

has 'location' => (
    is => 'ro',
    default => sub [0,0],
);

has 'message' => (
    is => 'ro',
    default => "<no message given>",
);

has 'actor' => (
    is => 'ro',
    default => undef,
);

1;