# frozen_string_literal: true

# The JavaScript and CSS bundles (app/assets/builds) are built by esbuild and
# Sass, not committed. Pages fail to render without them, so build them once if
# they are missing: a fresh checkout's specs then don't fail with 'The asset
# "application.css" was not found'. (After changing the JavaScript or CSS, run
# `yarn build` and `yarn build:css`, or keep `yarn build:watch` and
# `yarn build:css:watch` running.)
RSpec.configure do |config|
  config.before(:suite) do
    builds = Rails.root.join('app/assets/builds')
    {
      'react_islands.js' => 'build',
      'application.js' => 'build',
      'application.css' => 'build:css'
    }.each do |bundle, script|
      next if builds.join(bundle).exist?

      system('yarn', script, chdir: Rails.root.to_s) || raise("yarn #{script} failed; run `yarn install` first")
    end
  end
end
