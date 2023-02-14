# Pipelines

https://stackoverflow.com/questions/23235892/how-long-does-sonatype-staging-take-to-sync-my-artifacts-with-maven-central

./terragrunt.sh apply develop tech.go9 kubernetes-custom-stack 0.1.0-SNAPSHOT tar.gz

mvn dependency:copy -Dartifact=tech.go9:kubernetes-custom-stack:0.1.0-SNAPSHOT:tar.gz -DoutputDirectory=.