package RogueLike::Behaviour;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use RogueLike::Action;

# Something role-like. An Actor has one or more behaviours to
# produce an action.

sub next_action( $self, $actor ) {
}

package RogueLike::Behaviour::AlwaysSkip;
use strict;
use Filter::signatures;
use Moo 2;

use RogueLike::Action;

sub next_action( $self, $actor ) {
    RogueLike::Action::Skip->new()
}

package RogueLike::Behaviour::MoveTowards;
use strict;
use Filter::signatures;
use Moo 2;

use RogueLike::Action;

extends 'RogueLike::Behaviour';

has 'target' => (
    is => 'rw',
);

sub sign( $num ) {
    $num <=> 0    
}

# Move "close" to target, not onto target.
sub next_action( $self, $actor ) {
    # Keep a (globally?) cached terrain map with A* distances
    my $target_pos= $self->target->position;
    my $actor_pos= $actor->position;
    
    # Simple Manhattan distance
    my $diff= [ map { $target_pos->[$_] - $actor_pos->[$_] } 0..1 ];
    if(abs($diff->[0]) <= 1 and abs($diff->[1]) <= 1) {
        # We are already near the target
        return
    } else {
        my $direction= [map { sign($_) } @$diff];
        # We shouldn't make a beeline here...
        return RogueLike::Action::Walk->new(
            direction => $direction,
        );
    }
}

package RogueLike::Behaviour::HandToHandAttack;
use strict;
use Filter::signatures;
use Moo 2;

use RogueLike::Action;

# do a hand-to-hand attack

extends 'RogueLike::Behaviour';

has 'target' => (
    is => 'rw',
);

1;
