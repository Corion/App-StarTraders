#!perl -w
package RogueLike::HTTP;
use strict;
use Data::Dumper;
use Filter::signatures;
use feature 'signatures';

use RogueLike::LevelDisplay;
use RogueLike::Game;
use RogueLike::Actor;

use RogueLike::Demo;

use Dancer;

my ($g,$display,%players);
sub restart() {
    ($g,$display,%players) = RogueLike::Demo::setup_loop();
};

get '/restart' => sub {
    restart();
    redirect '/';
};

my %keymap= (
    'y' => sub { RogueLike::Action::Walk->new( direction => [ -1, -1 ] ) },
    'u' => sub { RogueLike::Action::Walk->new( direction => [  1, -1 ] ) },
    'h' => sub { RogueLike::Action::Walk->new( direction => [ -1,  0 ] ) },
    'j' => sub { RogueLike::Action::Walk->new( direction => [  0,  1 ] ) },
    'k' => sub { RogueLike::Action::Walk->new( direction => [  0, -1 ] ) },
    'l' => sub { RogueLike::Action::Walk->new( direction => [  1,  0 ] ) },
    'b' => sub { RogueLike::Action::Walk->new( direction => [ -1,  1 ] ) },
    'n' => sub { RogueLike::Action::Walk->new( direction => [  1,  1 ] ) },
    # I want to use TryEnterUp or have a checker "available actions"
    '<' => sub { RogueLike::Action::EnterUp->new() },
    '>' => sub { RogueLike::Action::EnterDown->new() },
    '.' => sub { RogueLike::Action::SkipTurn->new() },
    'q' => sub { $g->loop->running(0); undef },
);

sub get_player($player) {
    $players{ $player } if $player;
};

sub advance_clock {
    1 while ! $g->loop->process_all( $g->state );
};

post '/input' => sub {
    my $for = get_player( session->{player})
        or redirect '/choose';
    my $input = params->{input};
    my $action;
    if( my $new_action= $keymap{ $input }) {
        $action= $new_action->();
    } else {
        print "Unknown key: $input\n";
        return;
    };

    $for->next_action( $action )
        if $action;

    # We have at least one action, so we might advance
    advance_clock();
    
    return redirect '/';
};

sub get_roster($g) {
    my @need_input= $g->loop->process_all( $g->state );
    my %waiting = map { $_->name => 1 } @need_input;
    return [
        sort { $a->{name} cmp $b->{name} }
        map { { name => $_->name, waiting => $waiting{ $_->name } } } values %players
    ];
};

get '/waiting' => sub {
    return [
        grep { $_->{waiting} } @{get_roster($g)}
    ]
};

get '/choose' => sub {
    template 'choose', { roster => get_roster($g) };
};

post '/choose' => sub {
    my $player = params->{player};
    session player => $player;
    print STDERR "Activating player '$player'\n";
    return redirect '/';
};

get '/' => sub {
    restart unless $g;

    my $for = get_player( session->{player});
    if( ! $for) {
        return redirect '/choose'
    };
    if(! $g->loop->running ) {
        print STDERR "Game ended";
        return "Game ended";
    };

    my $time= $g->loop->gametime;
    my $name= $for->name;
    my $level= $for->dungeon_level;
    die "Player $name without a dungeonlevel ?!" . Dumper $for
        unless $level;
    my @lv = $display->as_string( $g->state, $level );

    my $e= $for->energy;
    my $lv= $level->terrain->name;
    my $d= $level->depth;
    my $prompt = "$lv:$d | $e $time $name: Action>";
    
    template 'level', {
        level => \@lv,
        prompt => $prompt,
        roster => get_roster($g),
        player => $for,
    };
};

1;