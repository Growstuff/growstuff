# Git pre-commit hook
# To install, run "rake hooks"

if git diff-index --quiet HEAD --; then
        # no changes between index and working copy; just run tests
        rspec spec
else
        # Test the version that's about to be committed,
        # stashing all unindexed changes
        git stash -q --keep-index
        rspec spec
        git stash pop -q
fi
