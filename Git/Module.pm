package Git::Module;

use strict;

use IO::File;
use IO::Dir;

use fields qw(name base);

sub create {
  my ($class, $name, $base) = @_;

  my $self = bless {}, $class;
  $self->{name} = $name;
  $self->{base} = $base;
  return $self;
}

1;

