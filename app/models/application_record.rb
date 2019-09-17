class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.per_page = 12
end
