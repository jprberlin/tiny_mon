require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class UserAccountsControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    
    login_with @user
  end

  test "should get new" do
    get :new
    assert_response :success
  end
  
  test "should create user account mapping" do
    second_user = User.create(:full_name => 'Jane Doe', :email => 'jane.doe@example.com', :password => '12345', :password_confirmation => '12345')
    assert_difference 'UserAccount.count' do
      assert !second_user.can_switch_to_account?(@account)
      post :create, :user_account => { :email => 'jane.doe@example.com' }
      assert_response :redirect
      assert_not_nil flash[:notice]
      assert second_user.can_switch_to_account?(@account)
    end
  end
  
  test "should not create user account mapping if user does not exist" do
    assert_no_difference 'UserAccount.count' do
      post :create, :user_account => { :email => 'foo@bar.com' }
      assert_response :success
      assert_nil flash[:notice]
      assert assigns(:user_account).errors.on(:email)
    end
  end
  
  test "should remove user account mapping" do
    second_user = @account.users.create(:full_name => 'Jane Doe', :email => 'jane.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    assert_difference 'UserAccount.count', -1 do
      delete :destroy, :id => UserAccount.last
      assert_response :redirect
      assert_not_nil flash[:notice]
    end
  end
end