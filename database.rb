require 'sequel'

class Database
  def initialize
    $DB = Sequel.sqlite('hugs.db')
  end
end
