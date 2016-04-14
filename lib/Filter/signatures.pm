package Filter::signatures;
use strict;
use Filter::Simple;

FILTER_ONLY
    code => sub {
        # THis should also support
        # sub foo($x,$y,@) { ... }, throwing away additional arguments
        s!\bsub\s*(\w+)\s*(\([^)]*?\@?\))\s*{\s*$!sub $1 { my $2=\@_;!mg;
    },
    executable => sub {
            s!^(use\s+feature\s*(['"])signatures\2);!#$1!mg;
            #print $_;
    },
    ;

1;