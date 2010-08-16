class SelectCheckBoxStep < ScopableStep
  property :name, :string
  
  validates_presence_of :name
  
  def run!(session, check_run)
    with_optional_scope(session) do |scope|
      scope.check(self.name)
    end
  end
end
