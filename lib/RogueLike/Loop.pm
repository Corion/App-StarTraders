package RogueLike::Loop;
use Filter::signatures;
use Moo::Lax;

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
            $_->avatar, $_->energy, $_->speed;
    };
};

sub get_next_to_act( $self, $state ) {
    # Sort the actors by energy
    # We should sort not only by energy but also by whether
    # an actor has chosen to skip "this turn", that is, wait until the next tick
    # That action would cost $actor->speed instead of costing $action->action_cost
    # Ideally, we'll keep @actors always in sorted order as a priority queue
    # instead of sorting it all the time here
    my(@next)= sort { $b->energy <=> $a->energy } (@{ $state->actors });

    for( @next ) {
        print sprintf "% 3s  % 5d  % 5d\n",
            $_->avatar, $_->energy, $_->speed;
    };

    my $next= shift @next;
    
    # Well, do a priority queue insert here
    @{ $state->actors }= (@next, $next);
    
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
    $self->gametime( $self->gametime +1 );
}

# Process one actor
sub process( $self, $state, $actor ) {
    my $done;
    my $action= $actor->get_action();

    # If we don't get an action, the current actor is not ready yet
    # (we're turn-based).
    return unless $action;

    warn "Action: $action";
    
    my $actor_done;
    while( ! $done ) {
        ( $done, my $alternative )= $action->perform($state, $actor);
        if( $alternative ) {
            #warn "Switching to alternative: $alternative";
            $action= $alternative;

        } elsif( $done ) {
            #warn "Deducting energy";
            # This action was performed, deduct its cost
            $actor->energy( $actor->energy - $action->cost );
            $actor_done= 1;
        } else {
            # No action could be performed
            # If this is the player, ask for a new action
            # Otherwise, umm, ignore.
            $actor_done= 0;
        };
    };
    
    #warn sprintf "%s done.", $actor->avatar;
    return $actor_done
}

# Process all moves of all ready actors
sub process_all($self,$state) {
    my $ok= 1;
    while( $self->running and my $actor= $self->get_next_to_act($state)) {
        #warn "Next actor: " . $actor->avatar;
        $ok= $self->process( $state, $actor );
        last if not $ok;
    };

    # Now we can distribute new energy as all are exhausted
    if( $ok ) {
        #warn "New energy for all";
        $self->tick( $state );
        #$self->dump_energy_levels( $state );
    };
}

1;