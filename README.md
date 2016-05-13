git2pom
======

Creates Maven projects from multiple Git repos.

Set up
------

Configure your `PATH`:

    export PATH="$HOME/tools/git2pom:$PATH"

Define the `GIT_SERVER` environment variable to point to github or your personal/enterprise Git server:

    export GIT_SERVER="ssh://git@my-usual-git-server:1234"

Usage
------

Create a new project by branching multiple Git repositories:

    git2pom clone --name hack-the-thing github.com:xxx/yyy.git other/project.git

Add more modules:

    git2pom add --base stable foo/bar.git

Open the `pom.xml` file in your favorite IDE (like IntelliJ) to manage the projects synchronously.
