# frozen_string_literal: true

desc "Install git hooks"
task :hooks do
  FileUtils.symlink '../../script/pre-commit.sh', '.git/hooks/pre-commit',
                    force: true
end
