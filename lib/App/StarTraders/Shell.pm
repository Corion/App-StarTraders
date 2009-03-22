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
    initializer => 'setup_shell',
);

no Moose;

sub run {
    my ($self) = @_;
    $self->term->run();
};

sub setup_shell {
    my ($self,$slotname,$setter) = @_;
    warn "Setting up the shell";
    my $term = Term::ShellUI->new(
        commands => {
            'scan' => {
                  desc => "Scan the current solar system",
                  maxargs => 0, args => sub { },
                  proc => sub { $self->describe_system },
              },
            'quit' => {
                  desc => "Quit this program", maxargs => 0,
                  method => sub { shift->exit_requested(1); },
              }},
        #history_file => '~/.shellui-synopsis-history',
    );
    $setter->($term);
    $term
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