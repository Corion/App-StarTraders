package RogueLike::Action;
use strict;
use Filter::signatures;
use Moo;

has 'cost' => (
    is => 'ro',
    default => sub { 1000 },
);

sub perform {
    # Default is to do nothing
    warn "No action?";
    return (1, undef); # we do nothing, but we do it well
}

package RogueLike::Action::Information;
use Filter::signatures;
use Moo;

has 'cost' => (
    is => 'ro',
    default => sub { 0 },
);

has 'message' => (
    is => 'ro',
);

sub perform( $self, $state, $actor ) {
    print $self->message, "\n";
    return (0, undef); # we do nothing, but we do it well
}

package RogueLike::Action::Skip;
use Filter::signatures;
use Moo;

has 'cost' => (
    is => 'ro',
    default => sub { 100 },
);

sub perform {
    warn "Skipping";
    return (1, undef); # we do nothing, but we do it well
}

package RogueLike::Action::Walk;
use Filter::signatures;
use Moo;
use feature 'signatures';
extends 'RogueLike::Action';

has 'direction' => (
    is => 'ro',
    default => sub { [0,0] },
);

sub perform( $self, $state, $actor ) {
    my $pos= $actor->position;
    my $new_pos= [ @{ $pos } ];
    my $vec= $self->direction ;
    for( 0..$#{ $vec }) {
        $new_pos->[$_] += $vec->[ $_ ]
    };
    
    if( my $other= $state->actor_at( $new_pos )) {
        # Uhoh
        # Is it a rock and can we push it?
        return 0, RogueLike::Action::Information->new(
            message => "It would be impolite to step on " . $other->avatar,
        );
        
    } elsif( $state->can_enter( $actor, $new_pos )) {
        $actor->position( $new_pos );
        return (1, undef );

    } elsif( my $barrier= $state->barrier_at($new_pos)) {

        # Is it a door and can we open it?
        if( $barrier->type->{'openable'} and $actor->capability->{'hands'}) {
            return( 0, RogueLike::Action::Open->new(
                object => $barrier,
            ));
        };
    
    } else {
        # We can't go that way, but we can't do anything about it either
        return 0, RogueLike::Action::Information->new(
            message => "We can't do that",
        );
    };
}

package RogueLike::Action::Open;
use Filter::signatures;
use Moo;
use feature 'signatures';
extends 'RogueLike::Action';

has 'object' => (
    is => 'ro',
);

sub perform( $self, $state, $actor ) {
    my $pos= $actor->position;

    use Data::Dumper;
    #warn Dumper $self->object;
    #warn $self->object->avatar;
    
    $self->object->open_state(1);
    warn "Opened:";
    warn Dumper $self->object;
    warn $self->object->avatar;
    return (1, undef );
}

1;