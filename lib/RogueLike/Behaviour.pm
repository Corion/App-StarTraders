package RogueLike::Behaviour;
use strict;
use Filter::signatures;
use Moo::Lax;

use RogueLike::Action;

# Something role-like. An Actor has one or more behaviours to
# produce an action.

sub next_action( $self, $actor ) {
}

package RogueLike::Behaviour::AlwaysSkip;
use strict;
use Filter::signatures;
use Moo::Lax;

use RogueLike::Action;

sub next_action( $self, $actor ) {
    RogueLike::Action::Skip->new()
}

package RogueLike::Behaviour::MoveTowards;
use strict;
use Filter::signatures;
use Moo::Lax;

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
    #} else {
    #    # Just skip
    #    return RogueLike::Action::Skip->new();
    }
}

package RogueLike::Behaviour::BrawlAttack;
use strict;
use Filter::signatures;
use Moo::Lax;

use RogueLike::Action;

extends 'RogueLike::Behaviour';

has 'target' => (
    is => 'rw',
);

# If we can attack, attack
# Otherwise, move towards goal

1;