require "rake"

# Borrowed with gratitude from: https://qiita.com/aeroastro/items/c97bd26ce8b8818b6bed
RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.load_tasks # Load all the tasks just as Rails does (`load 'Rakefile'` is another simple way)
  end

  config.before(:each) do
    Rake.application.tasks.each(&:reenable) # Remove persistency between examples
  end
end
