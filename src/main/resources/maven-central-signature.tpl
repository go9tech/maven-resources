%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: go9admin
Name-Comment: Go9 Sonatype Jira Admin
Name-Email: sonatype-jira-admin@go9.tec
Expire-Date: 0
Passphrase: $GPG_PASSPHRASE
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done