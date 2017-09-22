#!perl -w
use strict;

package RPG::Effect;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

has 'name' => (
    is => 'ro',
);

has 'base_attribute' => (
    is => 'ro',
);

has 'affected_attribute' => (
    is => 'ro',
);

has 'buff' => ( # or debuff...
    is => 'ro',
);

has 'scale' => (
    is => 'ro',
);

has 'conferred_by' => (
    is => 'ro',
    weaken => 1,
);

has 'min' => ( # minimum value, capped
    is => 'ro',
);

has 'max' => ( # maximum value, capped
    is => 'ro',
);

# For each tick, we regenerate items
# ideally, we would disconnect ourselves from the per-tick mechanic here
# and calculate the added value by calculating the regeneration size * timespan

# non-stacking means simply reset the timeout counter
# stacking means to add the effect to the list of active effects
# recharging items could also be done through this mechanism except that
# this mechanism shouldn't be tied to the per-tick calculations as
# "once per day" does not translate to "half a charge at midday" (or does it?)
# but this could mean that two items "at once per day" could translate to
# "effect at midday", at least if the effect is tied to the character, not
# to the item.

sub _min {
    my $min = shift;
    for( @_ ) {
        next if ! defined $_;
        if( $min > $_ ) { $min = $_ } 
    }
    $min
};

sub _max {
    my $max = shift;
    for( @_ ) {
        next if ! defined $_;
        if( $max < $_ ) { $max = $_ } 
    }
    $max
};

sub apply( $self, $base, $effects ) {
    # updates $effects as a hash of modifiers
    $effects->{ $self->affected_attribute } ||= {
        buff => 0,
        scale => 1,
        min => $self->min,
        max => $self->max,
    };
    #my $min_v = defined $self->min ? $self->min : '-';
    #my $max_v = defined $self->max ? $self->max : '-';
    #warn sprintf "Changing %s: Buffing by %d, scaling by %0.2f%%, range(%s,%s)\n", $self->affected_attribute, ($self->buff || 0), ($self->scale || 0), $min_v, $max_v;
    $effects->{ $self->affected_attribute }->{ buff } += $self->buff || 0;
    $effects->{ $self->affected_attribute }->{ scale } += $self->scale || 0;
    $effects->{ $self->affected_attribute }->{ min } = _max( $self->min, $effects->{ $self->affected_attribute }->{ min } );
    $effects->{ $self->affected_attribute }->{ max } = _min( $self->max, $effects->{ $self->affected_attribute }->{ max } );
}

package RPG::Stats;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# What is this class needed for at all?!

# so much boilerplate, so little understanding of what's really needed
sub current($self) {
    $self
}

sub max($self) {
    $self->{_max}
}

package RPG::StatsActor;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# The effects currently active on the player (or wherever)
has 'active_effects' => (
    is => 'ro',
    default => sub { [] },
);

sub add_effect($self,@effects) {
    push @{$self->active_effects},@effects;
    # We need to mark that we want to recalculate here:
    delete $self->{current}
}

# Formula is
# base*(1+sum(scale)) + sum(buffs)
# Only UNMODIFIED attributes are taken into consideration, to prevent
# stacking loops where attribute a affects attribute b, which next turn
# affects attribute a again (except usually more complicated)
sub get_effects( $self, $base, $effects ) {
    for my $effect ( @{ $self->active_effects }) {
        $effect->apply( $base, $effects );
    }
};

=head2 C<< ->get_effects_delta( $base } >>

    my $active_effects = $player->get_effects_delta( {} )

Returns a hashref with the list of active effects beyond what is already listed
in the C<$base> hash.

=cut

sub get_effects_delta ( $self, $base ) {
    $self->get_effects( $base, \my %effects );

    \%effects
};

sub _min {
    my $min = shift;
    for( @_ ) {
        next if ! defined $_;
        if( $min > $_ ) { $min = $_ } 
    }
    $min
};

sub _max {
    my $max = shift;
    for( @_ ) {
        next if ! defined $_;
        if( $max < $_ ) { $max = $_ } 
    }
    $max
};


# This is where life choices accumulate, like (randomized) gains through
# levelling or permanent bonuses from consuming items
# Why not have them as a list too?! Prioritize that list/sort it after expiry
# and caching becomes possible. The Journal is everywhere.
# Consider "baking"/consolidating the effects. At least all permanent effects
# can be consolidated, as can all effects lasting longer than some certain
# tick period or until the inventory gets changed.
# Maybe the caching should be considered only after it really becomes a problem.
# If this scheme gets applied to items too (like recharging fireball swords),
# then caching will become an issue.
# Note that stats are only interesting upon player actions (combat,skill checks)
# so maybe having the whole thing be recalculated dynamically isn't actually
# that big a deal

sub apply_effects( $self, $effects_delta ) {
    my $base = $self->get_base_attributes;

    # This should basically be a delegating objects to $player, I think
    my %res;
    # $player should have a method listing all attributes instead of
    # us iterating over the keys...
    # And really, we should think of caching early, that is, caching a
    # "generation" of the player so we don't recalculate. But hunger is
    # ever-present, so we'll always recalculate?!
    for my $attr (keys %$effects_delta) {
        if( $effects_delta->{ $attr }) {
            $res{ $attr } = ($base->{$attr}|| 0) * ($effects_delta->{$attr}->{scale} || 1)+ ($effects_delta->{$attr}->{buff} || 0);
            if( defined( my $min = $effects_delta->{ $attr }->{min})) {
                $res{ $attr } = _max( $res{$attr}, $min );
            };
            if( defined( my $max = $effects_delta->{ $attr }->{max})) {
                $res{ $attr } = _min( $res{$attr}, $max );
            };
        } else {
            $res{ $attr } = $base->{$attr}; 
        }
    }

    # Cap negative numbers to zero
    # Maybe we should have this per-attribute
    # This should use ->min, ->max from the effects
    # but should also respect some limits from the world
    for( values %res) {
        $_ = 0 if $_ < 0
    }

    \%res
}

sub remove_effects( $self, $crit ) {
    @{ $self->active_effects } = grep { !$crit->() } @{ $self->active_effects };
    # We need to mark that we want to recalculate here:
    delete $self->{current}
};

sub get_base_attributes( $self ) {
    {}
}

sub current( $self ) {
    $self->{current} ||= do {
        my $active_effects= $self->get_effects_delta({});
        $self->apply_effects($active_effects);
    }
}

package RPG::Item;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

has effects => (
    is => 'ro',
    default => sub { [] },
);

has name => (
    is => 'rw',
    default => sub { '' },
);

has itemclass => (
    is => 'ro',
    default => sub { '' },
);

has symbol => (
    is => 'ro',
    default => sub { '' },
);

has weight => (
    is => 'ro',
    default => 1,
);

sub allow_container_change( $self, $action, $old, $new ) {
    # The callback to find whether a transaction is allowed
    # $old->{bearer} / $new->{bearer}
    # Returns status and an explaining message
    # The message can be undef

    return (1,undef)
};

# How do Actors interact with Items?!
# Are actions predetermined by the itemclass?!
# Maybe we notify each item that its "worn"
# status (or whatever) has changed:
sub container_change( $self, $action, $old, $new ) {
    # action can be [ picked_up, dropped, stashed, worn, taken_off, traded ]
    # Inspect $old->{bearer} / $new->{bearer}
    #         $old->{container} / $new->{container}
    #         $old->{container_type} / $new->{container_type} ("worn" is a container?!)

    # add/remove our effects on the (former) bearer
    if( $action =~ /^(picked_up|dropped|traded)$/ and $old->{bearer} != $new->{bearer} ) {
        $old->{bearer}->remove_effects( sub{ $_->conferred_by() == $self });
        
        $new->{bearer}->add_effects( $self->container_effects( $new ));
    };
};

sub container_effects( $self, $container ) {}

package RPG::Item::DunceCap;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

extends 'RPG::Item';

sub container_effects( $self, $container ) {
    my @effects;
    if( $container->type eq 'worn' ) {
        push @effects, RPG::Effect->new(
            { name => 'dunce cap',
              base_attribute => 'intelligence',
              affected_attribute => 'intelligence',
              buff => -15,
              scale => 0,
              conferred_by => $self,
              min => 3,
            },
        );
    };
    @effects
};

package RPG::Container;
use strict;
use Moo::Lax;

has items => (
    is => 'ro',
    default => sub { [] },
);

package main;
use strict;
use Carp qw(croak);
our %effects;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Test::More tests => 5;

sub min {
    my $min = shift;
    for( @_ ) {
        if( $min > $_ ) { $min = $_ } 
    }
    $min
};

# All known effects
# Each effect has a name, an attribute, a fixed contribution size,
# and a contribution factor which is relative to 1.

#%effects = (
#    health_regeneration => { name => 'regeneration', attribute => 'health', buff => 1, scale => 0 },
#    mana_regeneration => { name => 'regeneration', attribute => 'mana', buff => 1, scale => 0 },
#);

sub roll($dice) {
    $dice =~ /^(\d+)d(\d+)(?:\+(\d+))?$/i or croak "Don't know what die this is: '$dice'";
    my( $count, $sides, $sum ) = ($1,$2,$3);
    $sum ||= 0;
    for( 1..$count ) {
        $sum += int(rand($sides)+1)
    };
    $sum
}

my $player = RPG::StatsActor->new(
    active_effects => [map {RPG::Effect->new(%$_)} (
    # Initial "effects" basically calculating the base player stats
    # Having them here means additional work when displaying the stats?!
        { name => 'roll.intelligence', base_attribute => '', affected_attribute => 'intelligence', buff => roll('3d6') },
        { name => 'roll.wisdom', base_attribute => '', affected_attribute => 'wisdom', buff => roll('3d6') },
        { name => 'roll.strength', base_attribute => '', affected_attribute => 'strength', buff => roll('3d6') },
        { name => 'roll.constitution', base_attribute => '', affected_attribute => 'constitution', buff => roll('3d6') },
        { name => 'roll.health', base_attribute => 'constitution', affected_attribute => 'health', buff => roll('4d3') },
    # ideally, the above could be consolidated/cached here
    # How can we apply the class/body caps here?!

    # Permanent effects, affecting the maximum attributes of the player and base regeneration
        { name => 'robust', base_attribute => '', affected_attribute => 'health', buff => 0, scale => 0.10 },

    # Regenerative effects, affecting the current attributes of the player
        { name => 'regeneration', base_attribute => 'constitution', affected_attribute => 'health', buff => 1, scale => 0 },
        { name => 'vigorous_regeneration', base_attribute => 'constitution', affected_attribute => 'health', buff => 0, scale => 0.10 },
        { name => 'regeneration', base_attribute => 'intelligence', affected_attribute => 'mana', buff => 1, scale => 0 },
        { name => 'ring of mana regeneration', base_attribute => '', affected_attribute => 'mana', buff => 1, scale => 0, ratio => 'per tick' },
    # World/game engine caps should be applied here
    )]);
use Data::Dumper;
#warn Dumper \@active_effects;

# we should strip out all attributes where max=current according to the rules

my $int = $player->current->{intelligence};
cmp_ok $int, '>', 2, "We have 3d6 intelligence"
    or diag Dumper $player->current;
cmp_ok $int, '<', 19, "We have 3d6 intelligence"
    or diag Dumper $player->current;

# Wear a dunce cap
$player->add_effect( RPG::Effect->new(
    { name => 'dunce cap', base_attribute => 'intelligence', affected_attribute => 'intelligence', buff => -15, scale => 0, min => 3 },
));

# Here we need some hard world limits like having the lower limit on INT
# be 3 or something to that regard
cmp_ok $player->current->{intelligence}, '>', 0, "Wearing a dunce cap limits our intelligence"
    or diag Dumper $player->current;
cmp_ok $player->current->{intelligence}, '<', 4, "Wearing a dunce cap limits our intelligence"
    or diag Dumper $player->current;

# we should strip out all attributes where max=current according to the rules

# Remove the dunce cap now
$player->remove_effects(sub{ $_->{name} eq 'dunce cap'});

is $player->current->{intelligence}, $int, "Removing the cap restores our intelligence"
    or diag Dumper $player->current;

# we should strip out all attributes where max=current according to the rules

# How will effects be attached/connected with the items?!

# How to structure the "lensed" attributes?
# We have lenses for "base", "current" and "base maximum" and "current maximum",
# where
# "base" is the attribute provided by the player body
# "base maximum" is the current set of maximum values allowed for the attributes
# "current" is the current set of attributes
# "current maximum" is the set of maximum values for each attribute
# If a player shapeshifts, do they get a new body? What happens if they
# shapeshift back?! Maybe they either permanently get a new (stock) body
# or ther intermediate body is just another effect.
# The player body/class has its own set of maximum attributes
# Maybe the game world itself also wants to enforce a set maximum attributes

# Level gains change the base attributes
# Effects change the "current" set of attributes
# Each "maximum" is calculated from the "current" set of attributes
# This means that malleable attributes may not form a circular chain.

#$player->current->get('health');
#$player->max->get('health');

# base.constitution implies base.health.max
# base.intelligence implies base.mana.max
# there is no base.constitution.max
# there is no base.intelligence.max
# those would be the limits for that body/class, so maybe these should be there
