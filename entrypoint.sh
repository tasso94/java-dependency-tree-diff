#!/bin/bash

git pull

apt update && apt -y install ruby
gem install octokit

if [[ $(git diff origin/master HEAD --name-only | grep pom.xml$ | wc -c) -ne 0 ]]; then
    apt install -y nodejs npm rsync

    cd /github/workspace
    
    mvn -T 8C org.codehaus.mojo:license-maven-plugin:2.0.0:aggregate-add-third-party -Dlicense.includedScopes=test,compile,runtime,provided -Dlicense.excludedGroups="org\.camunda.*"
    find . -name 'THIRD-PARTY.txt' -exec rsync -R \{\} /pr \;

    git checkout -f origin/master
    mvn -T 8C org.codehaus.mojo:license-maven-plugin:2.0.0:aggregate-add-third-party -Dlicense.includedScopes=test,compile,runtime,provided -Dlicense.excludedGroups="org\.camunda.*"
    find . -name 'THIRD-PARTY.txt' -exec rsync -R \{\} /master \;

    echo -e "<details><summary>Dependency Tree Diff</summary><p>\n" >/github/workspace/dep-tree-diff.txt
    echo "\`\`\`diff" >>/github/workspace/dep-tree-diff.txt
    diff -r /master /pr >>/github/workspace/dep-tree-diff.txt
    echo "\`\`\`" >>/github/workspace/dep-tree-diff.txt
    echo "</p></details>" >>/github/workspace/dep-tree-diff.txt

    ruby /add-comment.rb dep-tree-diff.txt
else
    ruby /add-comment.rb
fi
