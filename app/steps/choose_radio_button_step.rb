class ChooseRadioButtonStep < Step
  property :name, :string
  
  validates_presence_of :name
  
  def run!(session, check_run)
    session.choose(self.name)
  end
end