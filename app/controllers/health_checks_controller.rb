class HealthChecksController < ApplicationController
  before_filter :login_required
  before_filter :find_account
  before_filter :find_site
  
  def index
    @search_filter = SearchFilter.new(params[:search_filter])
    if @site
      @health_checks = @site.health_checks.find_for_list(@search_filter, :order => 'health_checks.name ASC')
    else
      @health_checks = @account.health_checks.find_for_list(@search_filter, :order => 'sites.name ASC, health_checks.name ASC')
      render :action => 'all_checks' unless request.xhr?
    end
    
    render :update do |page|
      page.replace_html 'checks', :partial => 'list'
    end if request.xhr?
  end
  
  def new
    can_create_health_checks!(@account) do
      find_templates
      @health_check = @site.health_checks.build
    end
  end
  
  def create
    can_create_health_checks!(@account) do
      @health_check_template = HealthCheckTemplate.find_by_id(params[:template])
      @health_check = @site.health_checks.build(params[:health_check].merge(:template => @health_check_template))
      if params[:commit] == I18n.t("health_checks.template_form.preview")
        @health_check.get_info_from_template
        @preview = true
        render :action => 'new'
      else
        if @health_check.save
          flash[:notice] = I18n.t('flash.notice.created_health_check', :health_check => @health_check.name)
          redirect_to account_site_health_check_path(@account, @site, @health_check)
        else
          render :action => 'new'
        end
      end
    end
  end
  
  def show
    @health_check = @site.health_checks.find_by_permalink!(params[:id])
    @comments = @health_check.latest_comments.find(:all, :limit => 5)
    @comments_count = @health_check.comments.count
  end
  
  def edit
    can_edit_health_checks!(@account) do
      @health_check = @site.health_checks.find_by_permalink!(params[:id])
    end
  end
  
  def update
    can_edit_health_checks!(@account) do
      @health_check = @site.health_checks.find_by_permalink!(params[:id])
      if @health_check.update_attributes(params[:health_check])
        flash[:notice] = I18n.t('flash.notice.updated_health_check', :health_check => @health_check.name)
        redirect_to account_site_health_check_path(@account, @site, @health_check)
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    can_delete_health_checks!(@account) do
      @health_check = @site.health_checks.find_by_permalink!(params[:id])
      @health_check.destroy
      flash[:notice] = I18n.t('flash.notice.deleted_health_check', :health_check => @health_check.name)
      redirect_to account_site_health_checks_path(@account, @site)
    end
  end
  
protected
  def find_site
    @site = @account.sites.find_by_permalink!(params[:site_id]) if params[:site_id]
  end
  
  def find_templates
    @health_check_template = HealthCheckTemplate.find_by_id(params[:template])
    if !@health_check_template
      @health_check_templates = case params[:filter]
      when 'mine'
        current_user.health_check_templates.paginate(:order => 'name ASC', :page => params[:page])
      when 'public'
        HealthCheckTemplate.public_templates.paginate(:order => 'name ASC', :page => params[:page])
      else
        current_user.available_health_check_templates(:page => params[:page]) # already ordered and paginated
      end
    end
  end
end
