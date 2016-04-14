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
    if( $g ) {
        return [
            grep { $_->{waiting} } @{get_roster($g)}
        ]
    } else {
        # No game running, nothing to do
        return []
    };
};

get '/choose' => sub {
    if( $g ) {
        template 'choose', { roster => get_roster($g) };
    } else {
        # No game running, no list to show
        template 'choose', { roster => [] };
    }
};

my %connections;
post '/choose' => sub {
    my $player = params->{player};
    session player => $player;
    print STDERR "Activating player '$player'\n";
    $connections{ session->{sid} } = $player;
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

# This could become a nice? "interactive" framework:
#
# event: refresh fragment: #foo
# -or-
# event: refresh fragment: #foo from: /fragments/foo
# 
# for global fragments like sidebar

# On the server side, we need a triple association between
# #foo, /fragments/foo and generate_foo(), which is inconvenient.
# /fragments/fragment_map.json could provide that map to the client
# automatically so that changes in the site template don't necessitate
# changes in the JS client.

get '/events' => sub {
    # This expects a simple JavaScript eval-loop at the other end

    # Capture some Dancer information for later
    my $sid= session->{id};
    my $username= user->{displayname};
    my $player = get_player( session->{player});

    my $backlog= request->env->{"HTTP_LAST_EVENT_ID"};
    # We don't actually use the backlog. We simply make the client
    # request the complete current state.

    # immediately start the response and stream the content
    status 200;
    header("Content-Type", "text/event-stream");
    #header("Content-Length", "1000000"); # XXX Patch Dancer to not add a content length to streamed responses!
    event_stream(sub {
        my $writer= shift;
        # This is what we use to talk to the client
        my $listener; $listener= sub {
            my $event= HTTP::ServerEvent->as_string(
                data => encode_json($_[1]),
                event => 'update',
                id => $_[0],
                retry => $retry_ms,
            );

            if(! eval {
                $writer->write($event);
                1;
            }) { # Session has disconnected
                warn "Error while writing event: $@";
                delete $connections{ $sid };
                undef $listener;
                undef $writer;
                
                # XXX send all other clients an "this client is unavailable"
                #     message

            };
        };

        $connections{ $user->{uid} }->{ $sid }= $listener;
        # XXX Maybe we should clean out eventual old sessions+connections here

        # XXX Should we also support partial configs? Like only sending the nickname, or avatar image?
        #unshift @setup, {action => 'configure', config => $session_info };

        # Send the current roster for the (one) channel
        push @setup, get_roster_actions( @channels );

        my $ts= strftime "%Y-%m-%d %H:%M:%S", gmtime;

    });
};

1;