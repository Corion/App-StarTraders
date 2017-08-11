#!perl -w
package main;
use strict;
use lib 'lib';
use Data::Dumper;
use Filter::signatures;
use feature 'signatures';
# Note that the energy gameloop is basically a Future
# Think of a Future as returning a box, together with the promise that you
# will fill the box some time later with the value

use RogueLike::LevelDisplay;
use RogueLike::Game;
use RogueLike::Actor;

use RogueLike::Demo;

my ($g,$display) = RogueLike::Demo::setup_loop();

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

sub handle_input( $input ) {
    if( my $new_action= $keymap{ $input }) {
        my $act= $new_action->();
        return $act;
    } else {
        print "Unknown key: $input\n";
        return;
    };
};

my @need_input;
while( $g->loop->running ) {
    my $time= $g->loop->gametime;

    #warn sprintf "%d players need input", 0+@need_input;
    for my $player (@need_input) {
        print $_->message
            for $player->get_observations;
        my $name= $player->name;
        my $level= $player->dungeon_level;
        die "Player $name without a dungeonlevel ?!" . Dumper $player
            unless $level;
        $display->draw( $g->state, $level );

        my $e= $player->energy;
        my $lv= $level->terrain->name;
        my $d= $level->depth;
        print "$lv:$d | $e $time $name: Action>";
        my $action= <>;
        chomp $action;
        $action= handle_input( $action );

        $player->next_action( $action )
            if $action;
    };

    @need_input= $g->loop->process_all( $g->state );
};
