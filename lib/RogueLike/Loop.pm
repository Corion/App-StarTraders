package RogueLike::Loop;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

has running => (
    is => 'rw',
    default => 0,
);

has gametime => (
    is => 'rw',
    default => 0,
);

sub dump_energy_levels( $self, $state ) {
    print "Energy levels\n";

    my(@next)= sort { $b->energy <=> $a->energy } (@{ $state->actors });
    @{ $state->actors }= @next;
    
    for( @next ) {
        print sprintf "% 3s  % 5d  % 5d\n",
            $_->avatar, $_->energy, $_->effective_speed;
    };
};

sub get_next_to_act( $self, $state ) {
    # Sort the actors by energy
    # We should sort not only by energy but also by whether
    # an actor has chosen to skip "this turn", that is, wait until the next tick
    # That action would cost $actor->speed instead of costing $action->action_cost
    # Ideally, we'll keep @actors always in sorted order as a priority queue
    # instead of sorting it all the time here
    #my $actors= $self->rebuild_actors( $state );
    my $actors= $state->actors;

    #for( @$actors ) {
    #    print sprintf "% 3s  % 5d  % 5d\n",
    #        $_->avatar, $_->energy, $_->effective_speed;
    #};

    my $next= $actors->[0];
    
    # Well, do a priority queue insert here
    #@{ $state->actors }= (@next, $next);
    # Only do that if the action gets spent, in ->process
    
    if( $next and $next->energy >= 1000 ) {
        return $next;
    } else {
        # Nobody can move
        return undef
    };
}

# Dispense energy to each actor
sub tick( $self, $state ) {
    for my $actor (@{ $state->actors }) {
        $actor->tick();
    };
    $state->rebuild_actors();
    $self->gametime( $self->gametime +1 );
}

# Process one actor
sub process( $self, $state, $actor ) {
    my $done;
    my $action= $actor->get_action();

    # If we don't get an action, the current actor is not ready yet
    # (we're turn-based).
    return unless $action;

    #warn "Action: $action";
    
    my $actor_done;
    my @messages;
    while( ! $done ) {
        ( $done, my $alternative )= $action->perform($state, $actor);
        # Do we want to return an error(message) here too?
        
        #warn sprintf "%s proposes %s (%s)", $actor->name, $done||'retry', $alternative||"-";
        if( $alternative ) {
            #warn "Switching to alternative: $alternative";
            $action= $alternative;

        } elsif( $done ) {
            #warn "Deducting energy";
            # This action was performed, deduct its cost
            $actor->energy( $actor->energy - $action->cost );
            push @messages, $action->messages;
            $actor_done= 1;
            $state->rebuild_actors( $actor );
        } else {
            # No action could be performed
            # If this is the player, ask for a new action
            # Otherwise, umm, ignore.
            $actor_done= 0;
            $done= 1;
        };
    };
    
    #warn sprintf "%s done.", $actor->avatar;
    $actor_done, @messages
}

# Process all moves of all ready actors
sub process_all($self,$state) {
    my @need_input;
    while( $self->running and my $actor= $self->get_next_to_act($state)) {
        #warn "Next actor: " . $actor->avatar;
        my( $done ) = $self->process( $state, $actor );
        # Inform the actor/observer of the messages created through
        # the action(s)
        # How do we know who a message is for?!
        if( ! $done) {
            # Here, we could also issue a query to other actors for coordination
            # consuming no gametime
            push @need_input, $actor;
            last;
        };
    };

    # Now we can distribute new energy if all moves are exhausted
    if( $self->running and ! @need_input ) {
        $self->tick( $state );
    };
    
    return @need_input;
}

1;