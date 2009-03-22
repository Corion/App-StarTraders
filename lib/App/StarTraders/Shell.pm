package App::StarTraders::Shell;
use Moose;
use Term::ShellUI;

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
              }
         },
        #history_file => '~/.shellui-synopsis-history',
    );
    $term
};

sub complete_reachable {
    my ($self,$cmpl) = @_;
    my $str = substr $cmpl->{tokens}->[ $cmpl->{tokno} ], 0, $cmpl->{tokoff};
    [ grep { /^\Q$str\E/i } map { $_->name } grep { $_->is_visible } $self->ship->system->children ]
};

sub move_to_named {
    my ($self,$target) = @_;
    
    (my $item) = grep { $_->name =~ /^\Q$target\E/i } grep { $_->is_visible }$self->ship->system->children;
    if ($item) {
        $self->ship->move_to($item);
        $self->term->prompt($self->ship->system->name . ">");
    } else {
        print "I did not find any item for '$target' here.\n";
    };
};

sub describe_system {
    my ($self,$star) = @_;
    $star ||= $self->ship->system;
    
    print $star->name,"\n";
    for ($star->planets) {
        print "\t", $_->name, "\n";
    };
    print "Wormholes:\n";
    print( "\t", $_->target_system->name, "\n" ) for $star->wormholes;
    print "Ships:\n";
    print( sprintf "\t%s near %s\n", $_->name, $_->position->name, "\n" ) for $star->ships;  
};

1;