# frozen_string_literal: true

# The React bundle (app/assets/builds/react_islands.js) is built by esbuild, not
# committed. Pages that load it fail to render without it, so build it once if
# it is missing: a fresh checkout's specs then don't fail with 'The asset
# "react_islands.js" is not present in the asset pipeline'. (After changing the
# JavaScript, run `yarn build`, or keep `yarn build:watch` running.)
RSpec.configure do |config|
  config.before(:suite) do
    bundle = Rails.root.join('app/assets/builds/react_islands.js')
    next if bundle.exist?

    system('yarn', 'build', chdir: Rails.root.to_s) || raise('yarn build failed; run `yarn install` first')
  end
end
