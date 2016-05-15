package Git::Commands;

use strict;

use Getopt::Long;
use File::Basename qw(basename);
use Git::Project;
use Term::ANSIColor;

sub clone {
  my $id;
  my $name;
  my $base = "master";
  my $modules = [];

  GetOptions("name|n=s" => \$name,
             "base|b=s" => \$base)
    or die "Error in command line arguments";

  if (@ARGV == 0) {
    print STDERR "usage: clone [--name <project-name>] [--base <base-branch>] <repo1> <repo2> ...\n\n";
    die "Nothing to clone";
  }

  if (!$name) {
    print "Feature branch: ";
    $name = <STDIN>;
    chomp $name;
  }

  if (!$name) {
    die "The project name is missing"
  }

  # Prepare the project folder

  if (!$id) {
    $id = $name;
    $id =~ s/\W/-/;
  }

  if ( -e $id ) {
    die "The folder already exists: '$id'";
  }

  print "Creating folder '$id'\n";
  mkdir $id or die "Can't create folder";
  chdir $id;

  # Checkout the repositories
  foreach my $repository (@ARGV) {
    my $module = _clone($repository, $base, $name);
    push @$modules, $module;
  }

  my $project = Git::Project->create(".");
  $project->{id} = $id;
  $project->{name} = $name;
  $project->{modules} = $modules;

  $project->save();
}

sub _clone {
  my ($repository, $base, $branch) = @_;

  if ($ENV{'GIT_SERVER'}) {
    $repository = $ENV{GIT_SERVER}.'/'.$repository
  }

  print colored("Branching $base from $repository...\n", "green bold");

  system("git clone $repository -b $base");
  if ($? != 0) {
    die "Can't checkout from '$repository' ($?)";
  }

  my $name = basename($repository);

  if ($branch) {
    chdir $name;
    _switch_branch($branch);
    chdir "..";
  }

  return Git::Module->create($name, $base);
}

sub _switch_branch {
  my ($name) = @_;

  # Check the branch if it already exists
  `git branch -r | grep $name`;

  if ($? == 0) {
    system("git checkout $name");
  } else {
    system("git checkout -b $name");
  }
}

sub info {
  my $project = Git::Project->load(".");

  print "Project:\n";
  print "  Id: ".$project->{id}."\n";
  print "  Name: ".$project->{name}."\n";
  print "  Modules:\n";
  foreach my $module (@{$project->{modules}}) {
    print "    ".$module->{name}." (from ".$module->{base}.")\n";
  }
}

sub add {
  my $project = Git::Project->load(".");
  my $base = "master";

  GetOptions("base|b=s" => \$base)
    or die "Error in command line arguments";

  if (@ARGV == 0) {
    print STDERR "usage: add [--base <base-branch>] <repo1> <repo2> ...\n\n";
    die "Nothing to clone";
  }

  my $name = $project->{name};

  # Checkout the new repositories
  foreach my $repository (@ARGV) {
    my $module = _clone($repository, $base, $name);
    push @{$project->{modules}}, $module;
  }

  $project->save();
}

sub remove {
  my $project = Git::Project->load(".");

  if (@ARGV == 0) {
    print STDERR "usage: remove <module1> <module2> ...\n\n";
    die "Nothing to remove";
  }

  my $new_modules = [];
  foreach my $module (@{$project->{modules}}) {
    my $name = $module->{name};
    if (!grep(/\b$name\b/, @ARGV)) {
      push @$new_modules, $module;
    }
  }

  $project->{modules} = $new_modules;
  $project->save();
}

1;

