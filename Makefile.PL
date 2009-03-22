use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'App::StarTraders',
    'VERSION_FROM'  => 'lib/App/StarTraders.pm', # finds $VERSION
    'PREREQ_PM'    => {
                       'Moose' => 0,
                       'List::AllUtils' => 0,
                      },
    'ABSTRACT_FROM' => 'lib/App/StarTraders.pm', # retrieve abstract from module
    'AUTHOR'        => 'Max Maischein <corion@cpan.org>',
);

# To make Test::Prereq happy
1;
