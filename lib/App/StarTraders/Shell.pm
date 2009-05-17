package App::StarTraders::Shell;
use Moose;
use Term::ShellUI;
use List::Util qw(min);
use List::Part::SmartMatch 'sortp';

has universe => (
    is => 'ro',
    isa => 'App::StarTraders::SpaceTime',
);

has ship => (
    is => 'rw',
    isa => 'App::StarTraders::Ship',
);

has term => (
    is => 'rw',
    isa => 'Term::ShellUI',
    builder => 'build_shell',
);

no Moose;

sub run {
    my ($self) = @_;
    $self->term->run();
};

sub build_shell {
    my ($self) = @_;
    warn "Setting up the shell";
    my $term = Term::ShellUI->new(
        commands => {
            'scan' => {
                  desc => "Scan the current solar system",
                  maxargs => 0, args => sub { },
                  proc => sub { $self->describe_system },
              },
            'go' => {
                  desc => "Go to a place in the current solar system",
                  maxargs => 1, args => sub { my ($term,$cmpl) = @_; $self->complete_reachable( $cmpl ) },
                  proc => sub { $self->move_to_named($_[0]) },
              },
            'quit' => {
                  desc => "Quit this program", maxargs => 0,
                  method => sub { shift->exit_requested(1); },
              },
            'pick' => {
                  desc => "Pick up items",
                  maxargs => 2, args => [ sub { my ($term,$cmpl) = @_; $self->complete_item_names( $cmpl, $self->ship->position,$self->ship ) },
                                          sub { my ($term,$cmpl) = @_; $self->complete_item_quantities( $cmpl, $self->ship->position, $self->ship ) } ],
                  proc => sub { $self->pick_up_items($_[0],$_[1]) },
              },
            'drop' => {
                  desc => "Drop up items",
                  maxargs => 2, args => [ sub { my ($term,$cmpl) = @_; $self->complete_item_names( $cmpl, $self->ship, $self->ship->position ) },
                                          sub { my ($term,$cmpl) = @_; $self->complete_item_quantities( $cmpl, $self->ship,$self->ship->position ) } ],
                  proc => sub { $self->drop_items($_[0],$_[1]) },
              },
            'inventory' => {
                  desc => "Show your ships cargo",
                  maxargs => 0,
                  proc => sub { $self->describe_container($self->ship) },
            },
         },
        #history_file => '~/.shellui-synopsis-history',
        prompt => sub { $self->ship->system->name . ">" },
    );
    $term
};

sub complete_reachable {
    my ($self,$cmpl) = @_;
    # need definedness check
    my $str = substr $cmpl->{tokens}->[ $cmpl->{tokno} ], 0, $cmpl->{tokoff};
    $str ||= "";
    return [ grep { /^\Q$str\E/i } map { $_->name } grep { $_->is_visible } $self->ship->system->children ]
};

sub complete_item_names {
    my ($self,$cmpl,$source,$target) = @_;
    my $str = substr $cmpl->{tokens}->[ $cmpl->{tokno} ], 0, $cmpl->{tokoff};
    if ($source->can('items') && $target->can('items')) {
        return [ grep { /^\Q$str\E/i } map { $_->name } @{ $source->items } ]
    } else {
        return []
    };
};

sub complete_item_quantities {
    my ($self,$cmpl,$source,$target) = @_;
    my $str = substr $cmpl->{tokens}->[ $cmpl->{tokno} ], 0, $cmpl->{tokoff};
    if ($source->can('items') && $target->can('items')) {
        my $name = $cmpl->{tokens}->[ $cmpl->{tokno} -1 ];
        #warn "Completing '$name'";
        my $item = $self->universe->find_commodity($name);
        my $pos = $source->find_item_position($item);
        return [ grep { /^\Q$str\E/i } sort { $a <=> $b } (min($pos->quantity, $target->capacity_free), ($str||1)*10) ]
    } else {
        return []
    };
};

sub pick_up_items {
    my ($self,$name,$quantity) = @_;
    my $item = $self->universe->find_commodity($name);
    if ($item) {
        $self->ship->pick_up($item,$quantity);
    } else {
        print "I don't see any '$name' here.\n";
    };
};

sub drop_items {
    my ($self,$name,$quantity) = @_;
    my $item = $self->universe->find_commodity($name);
    if ($item) {
        my $pos = $self->ship->find_item_position($item);
        if ($pos->quantity >= $quantity) {
            $self->ship->drop($item,$quantity);
        } else {
            print sprintf "You only have %s %s.\n", $pos->quantity, $pos->name;
        };
    } else {
        print "You don't have any '$name'.\n";
    };
};

sub move_to_named {
    my ($self,$target) = @_;
    
    if (defined $target) {
        my @visible
            =  grep { $_->is_visible } $self->ship->system->children;
        (my $item) = sortp([
                         sub { $_->name =~ /^\Q$target\E/i },   # start of name
                         sub { $_->name =~ /\b\Q$target\E/i  }, # start of substring
                         sub { $_->name =~ /\Q$target\E/i  },   # simple substring
                       ], @visible);
        if ($item) {
            $self->ship->move_to($item);
        } else {
            print "I did not find any item for '$target' here.\n";
        };
    } else {
        print "I don't know where you want me to go.\n";
    }
};

sub describe_container {
    my ($self,$container) = @_;
    
    print sprintf "%s:\n", $container->name;
    for my $pos (@{ $container->items }) {
        print sprintf "%s units of %s.\n", $pos->quantity, $pos->item->name;
    };
};

sub describe_system {
    my ($self,$star) = @_;
    $star ||= $self->ship->system;
    
    print sprintf "%s (%s)\n", $star->name, $star->faction;
    for ($star->planets) {
        print "\t", $_->name, "\n";
    };
    print "Wormholes:\n";
    print( "\t", $_->target_system->name, "\n" ) for $star->wormholes;
    print "Ships:\n";
    print( sprintf "\t%s near %s\n", $_->name, $_->position->name, "\n" ) for $star->ships;
    my $p = $self->ship->position;
    if ($p->can('capacity') and @{ $p->items }) {
        for my $pos (@{ $p->items }) {
            print sprintf "There are %s units of %s here.\n", $pos->quantity, $pos->item->name;
        };
    };
};

1;