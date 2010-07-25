#!perl -w
use strict;
use B::Deparse;
my $deparse = B::Deparse->new("-p", "-sC");

my @rules;

# Framework
sub rule {
    my ($name, $predicates, $actions) = @_;
    push @rules, {
        predicates => $predicates,
        actions    => $actions,
        name       => $name,
    };
};

my $actor = {
    location => 'station',
    ship_state => 'docked',
    waypoints => [],
    cargo     => [],
    cooldown  => {},
};

my @events;

# Predicates
sub is($$) {
    my ($slot,$value) = @_;
    $value = [$value] unless ref $value;
    sub {
        die "Unknown slot $slot" unless exists $actor->{ $slot }; 
        my $msg = "Is $slot '$value'? " . (($actor->{ $slot }||'') eq $value ? "yes":"no");
        grep { ($actor->{ $slot }||'') eq $_ } @$value
    },
};

sub at($) {
    is location => $_[0];
};

sub empty($) {
    my $slot = $_[0];
    sub {
        die "Unknown slot '$slot'" if not exists $actor->{ $slot };
        my $res = ref $actor->{ $slot } eq 'ARRAY'
            ? @{ $actor->{ $slot } } == 0
            :    $actor->{ $slot } || 0 == 0;
        #warn "$slot are " . ($res?'':'not') . " empty";
        $res
    };
};

sub _not($) {
    my $predicate = $_[0];
    sub {
        not $predicate->();
    };
};

# Actions
sub add($$) {
    my ($slot,$item) = @_;
    sub {
        unshift @{ $actor->{ $slot } }, $item
    }
};

sub set($$) {
    my ($slot,$item) = @_;
    sub {
        $actor->{ $slot } = $item
    }
};

sub has($) {
    my ($slot) = @_;
    _not( empty $slot )
}

sub perform ($) {
    my ($action) = @_;
    sub {
        print "-->$action\n";
        no strict 'refs';
        goto &$action;
    };
};

sub add_event {
    push @events, [@_];
    @events = sort { $a->[0] <=> $b->[0] } @events
};

sub cooldown ($$$) {
    my ($kind, $span, $then) = @_;
        my $ts = time  + $span;
        add_event( $ts, $then );
};

# Should we have a proper (sorted, insertable) priority queue
# for events?
sub undock {
    print "Starting to undock\n";
    set( ship_state => 'undocking') ->();
    # What happens if the ship gets destroyed before it is undocked?
    # The cooldown would then fire and mess up the ship state
    cooldown ship_state => 2, sub {
        #print "Undocked";
        set( ship_state => 'undocked' )->();
    };
};

sub dock {
    print "Starting to dock\n";
    set( ship_state => 'docking') ->();
    # What happens if the ship gets destroyed before it is undocked?
    # The cooldown would then fire and mess up the ship state
    cooldown ship_state => 2, sub {
        #print "Docked";
        set( ship_state => 'docked' )->();
    };
};

sub sell {
    print "Selling cargo\n";
    set( cargo => [] )->();
};

sub move_to_waypoint {
    set( ship_state => 'moving' )->();
    my $wp = $actor->{waypoints}->[0];
    # What happens if the ship gets destroyed before it arrives?
    # The cooldown would then fire and mess up the ship state
    # We need to not store callbacks but the parameters for that
    # so we can eliminate all future events for an object that gets
    # destroyed/changed mid-flight
    print "Arrival at $wp in 5\n";
    set location => 'en_route';
    cooldown ship_state => 5, sub {
        set( ship_state => 'floating' )->();
        # Ugh - what if we changed our waypoint half-way? 
        set( location => $wp )->();
        shift @{ $actor->{ waypoints } };
    };
};

sub mine {
    print "Starting to mine\n";
    set( ship_state => 'mining') ->();
    # What happens if the ship gets destroyed before it is undocked?
    # The cooldown would then fire and mess up the ship state
    cooldown ship_state => 7, sub {
        #print "Full";
        set( ship_state => 'floating' )->();
        add( cargo => [ 100, 'minerals' ] )->();
    };
};
# Ruleset
rule do_undock => [ (has 'waypoints'), (is 'ship_state' => 'docked') ]
    => [ #sub { warn $actor->{ship_state} },
         perform 'undock',
       ],
    ;

rule do_start_travel => [
    (has 'waypoints'),
    (is 'ship_state' => ['floating','undocked']),
    #(is 'goal' => 'mine')
] => [
    perform 'move_to_waypoint',
];

rule do_travel => [
    (is 'ship_state' => 'moving'), (at 'en_route'),
] => [
    # wait
];

rule at_station_empty => [ at 'station', empty 'cargo', empty 'waypoints' ]
    => [ (add waypoints => 'asteroids'),
         set goal => 'mine',
       ],
    ;

# An "is_idle" predicate would be convenient
rule at_asteroids_empty => [ at 'asteroids', empty 'cargo', empty 'waypoints', is 'ship_state', 'floating' ]
    => [ perform 'mine',
       ],
    ;

rule at_asteroids_full => [ at 'asteroids', has 'cargo', empty 'waypoints' ]
    => [ (add waypoints => 'station'),
         set goal => 'sell',
       ],
    ;

rule at_station_full => [ at 'station', has 'cargo', empty 'waypoints', is 'ship_state', 'floating' ]
    => [ perform 'dock' ],
    ;

rule docked_at_station_full => [ at 'station', has 'cargo', empty 'waypoints', is 'ship_state', 'docked' ]
    => [ perform 'sell', ],
    ;

sub run {
    while (1) {
        print "\@$actor->{location} ($actor->{ship_state}) [$actor->{goal}]\n";
        # Fire all events that fire now
        my $now = time;
        my @now = grep { $_->[0] <= $now } @events;
        for my $ev (@now) {
            #warn "Event $ev";
            $ev->[1]->();
        };
        @events = grep { $_->[0] > $now } @events;
        # Find a rule that applies to our actor
        RULE: for my $rule (@rules) {
            #warn $rule->{name};
            #warn sprintf "%d predicates", 0+@{$rule->{predicates}};
            my $pc = 0;
            for my $p (@{$rule->{predicates}}) {
                #print "\n";
                #print $deparse->coderef2text($p);
                my $res = $p->();
                if (! $res) {
                    #print ", no ($res)";
                    next RULE;
                };
            };
            $pc++;
            #print "$pc: Firing rule $rule->{name}\n";
            for my $a (@{ $rule->{ actions }}) {
                my $nextstate = $a->();
                #warn $nextstate;
            };
            # First matching rule overrides all others
            last RULE;
        };
        sleep 1;
    };
};

run;