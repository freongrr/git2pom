package Git::Project;

use strict;

use IO::File;
use IO::Dir;
use Git::Module;

use fields qw(path id name modules);

sub create {
  my ($class, $path) = @_;

  my $self = bless {}, $class;
  $self->{path} = $path;
  return $self;
}

sub load {
  my ($class, $path) = @_;

  if (!defined($path)) {
    $path = ".";
  }

  my $self = $class->create($path);

  my $file = new IO::File("$path/project.info", "r")
    or die "No valid project in '$path'";

  while (<$file>) {
    if (/^id:\s*(.*)/) {
      $self->{id} = $1;
    } elsif (/^name:\s*(.*)/) {
      $self->{name} = $1;
    } elsif (/^--/) {
      my $modules = [];
      while (<$file>) {
        if (/^(.+):\s*(.+)/) {
          push @$modules, Git::Module->create($1, $2);
        }
      }
      $self->{modules} = $modules;
    }
  }

  undef $file;

  return $self;
}

sub module {
  my ($self, $name) = @_;
  foreach my $module (@{$self->{modules}}) {
    if ($module->{name} eq $name) {
      return $module;
    }
  }
  die "Can't find module $name";
}

sub save {
  my ($self) = @_;

  my $path = $self->{path};
  my $id = $self->{id};
  my $name = $self->{name};
  my $modules = join("\n", map { "        <module>".$_->{name}."</module>" } @{ $self->{modules} });

  # Write the POM file

  my $pom = new IO::File("$path/pom.xml", "w");
  $pom->write(<<__POM__);
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>adhoc</groupId>
    <artifactId>$id</artifactId>
    <version>0</version>
    <packaging>pom</packaging>
    <name>Project - $name</name>

    <modules>
$modules
    </modules>

</project>
__POM__

  undef $pom;

  # Write the info file

  my $info = new IO::File("$path/project.info", "w");
  $info->write(<<__INFO__);
id: $id
name: $name
--
__INFO__

  foreach my $module (@{$self->{modules}}) {
    $info->write($module->{name}.": ".$module->{base}."\n");
  }

  undef $info;
}

1;

