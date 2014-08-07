package RogueLike::Actor;
use strict;
use Filter::signatures;
use Moo;

use RogueLike::Action;

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

sub skip( $self ) {
    return RogueLike::Action::Skip->new({
        cost => $self->speed,
    });
}

# We are inert
sub get_action {
    return $_[0]->skip
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
use Moo;

extends 'RogueLike::Actor';

sub BUILDARGS( $self, %options ) {
    $options{ speed } //= 0;
    $options{ avatar } //= '*';
    \%options
}

package RogueLike::Actor::Player;
use Filter::signatures;
use Moo;

extends 'RogueLike::Actor';

has next_action => (
    is => 'rw',
);

sub BUILDARGS( $self, %options ) {
    $options{ energy } //= 1000; # we come in ready!
    $options{ speed } //= 100;
    $options{ avatar } //= '@';
    \%options
}

sub get_action( $self ) {
    if( $self->next_action ) {
        my $action= $self->next_action;
        $self->next_action( undef );
        return $action
    };
};

1;