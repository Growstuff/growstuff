# Git pre-commit hook
# To install, run "rake hooks"

# Test the version that's about to be committed, stashing all unindexed changes
git stash -q --keep-index
rspec spec
git stash pop -q
