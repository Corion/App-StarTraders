package RogueLike::Actor;
use strict;
use Filter::signatures;
use Moo::Lax;

use RogueLike::Action;

use Scalar::Util 'weaken';

# Should an actor be(come) a list of behaviours and compose its
# action decisions from such behaviours?
# So an actor that can open doors would "have" the door_open behaviour...

has 'energy' => (
    is => 'rw',
    default => sub { 0 },
);

has 'speed' => (
    is => 'rw',
    default => sub { 100 },
);

has 'position' => (
    is => 'rw',
    default => sub { [0,0] },
);

has 'avatar' => (
    is => 'rw',
    default => sub { '@' },
);

has 'name' => (
    is => 'rw',
    default => sub { 'unnamed actor' },
);

has 'dungeon_level' => (
    is => 'rw', # a weak ref
);

# The list of active effects on this Actor
# We still need to know how to apply these to the actor.
# Maybe all of ->effective_speed() etc. need to go through
# these.
has 'active_effects' => (
    is => 'ro',
    default => sub { [] },
);

sub skip( $self ) {
    return RogueLike::Action::Skip->new({
        cost => $self->speed,
    });
}

sub drain_energy( $self ) {
    if( $self->energy > 0 ) {
        $self->energy( 0 )
    }
}

# We are inert
sub get_action( $self ) {
    return $self->skip
}

sub can_open( $self, $barrier ) {
    # Humanoids can open any barrier
    return $self->is_humanoid
}

sub can_force( $self, $barrier ) {
    # We are currently non-violent
    0
}

sub is_humanoid( $self ) {
    0
}

sub set_dungeon_level( $self, $level ) {
    $self->dungeon_level( $level );
    #weaken $self->{dungeon_level};
}

=head2 C<< ->effective_speed >>

  my $energy= $actor->effective_speed;

Returns the effective speed of the actor. This
is the base C<speed>, modified
by any effects that slow or speed up the actor.

=cut

sub effective_speed( $self ) {
    # $self->effects
    $self->speed
}

sub tick( $self ) {
    my $energy= $self->energy;
    if( $energy < 1000 ) {
        $energy += $self->speed
    } else {
        # How do we handle "accumulated" energy?
        $energy= 1000;
    }
    $self->energy( $energy );
}

sub time_to_next_action {
    my( $self )= @_;
    my $cost= $self->action_cost();
    if( $cost > $self->energy ) {
        int( ( $cost - $self->energy ) / $self->speed ) +1
    } else {
        0
    }
}

package RogueLike::Actor::Rock;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Actor';

sub BUILDARGS( $self, %options ) {
    $options{ speed } //= 0;
    $options{ avatar } //= '*';
    $options{ name } //= '(a) rock';
    \%options
}

package RogueLike::Actor::Player;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Actor';

has next_action => (
    is => 'rw',
);

sub BUILDARGS( $self, %options ) {
    $options{ energy } //= 1000; # we come in ready!
    $options{ speed } //= 100;
    $options{ avatar } //= '@';
    $options{ name }//= 'PlayerOne';
    #$options{ capability }//= {};
    #$options{ capability }->{ hands } //= 1;
    \%options
}

sub get_action( $self ) {
    if( $self->next_action ) {
        my $action= $self->next_action;
        $self->next_action( undef );
        return $action
    };
};

# Well, once we polymorph, this becomes more complicated
sub is_humanoid( $self ) {
    1
}

# Can we create an "needs user input" behaviour?
package RogueLike::Actor::BehaviourDriven;
use Filter::signatures;
use Moo::Lax;

extends 'RogueLike::Actor';

has behaviours => (
    is => 'rw',
    default => sub { [] }, # should we have a default "skip" behaviour?
);

sub get_action( $self ) {
    for my $beh (@{ $self->behaviours }) {
        my $action= $beh->next_action( $self );
        return $action
            if $action;
    };
};

package RogueLike::Actor::Pet;
use Filter::signatures;
use Moo::Lax;

use RogueLike::Behaviour;

extends 'RogueLike::Actor::BehaviourDriven';

# This should become a list...
has 'owner' => (
    is => 'rw',
);

sub BUILDARGS( $self, %options ) {
    $options{ speed } //= 150;
    $options{ avatar } //= 'c';
    $options{ name } //= '(a) cat';
    # We need an owner!
    $options{ behaviours } //= [
        RogueLike::Behaviour::MoveTowards->new(
            target => $options{ owner },
        ),
        RogueLike::Behaviour::AlwaysSkip->new(
        ),
    ];
    \%options
}

1;