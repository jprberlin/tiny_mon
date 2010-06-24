class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :user_accounts
  has_many :accounts, :through => :user_accounts
  
  belongs_to :current_account, :class_name => 'Account'
  
  def switch_to_account(account)
    update_attribute(:current_account_id, account.id)
  end
  
  def can_switch_to_account?(account)
    !UserAccount.find_by_user_id_and_account_id(self.id, account.id).nil?
  end
end