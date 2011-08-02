#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

include ApplicationHelper

class UsersController < ApplicationController
  
  before_filter :login_required
  layout 'main'

  private

  def init_cache(controller_name = request.parameters["controller"])
    if params[:getent] == "1"
      super "getent_passwd"
    else
      super
    end
  end

  def save_roles (userid,roles_string)
    all_roles = Role.find :all
    roles = roles_string.split(",")
    my_roles=[]
    all_roles.each do |role|
      role.id=role.name
      if role.users.include?(userid)
       if roles.include?(role.name)
        # already written - do nothing
        roles.delete(role.name)
       else
        # remove item
        role.users.delete(userid)
        role.save
        roles.delete(role.name)
       end
      end
    end
    roles.each do |role|
      # this should be added
      r = Role.find(role)
      r.id=r.name
      r.users << userid
      r.save
    end
  end


  # Initialize GetText and Content-Type.
  init_gettext "webyast-users-ui"

  public

  def initialize
  end

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    yapi_perm_check "users.usersget"
    if params[:getent] == "1"
      respond_to do |format|
        format.html { render  :xml => GetentPasswd.find.to_xml }
        format.xml { render  :xml => GetentPasswd.find.to_xml }
        format.json { render :json => GetentPasswd.find.to_json }
      end
      return
    end
    @users = User.find_all params
    if @users.nil?
      unless request.format.html?
        Rails.logger.error "No users found."
        render ErrorResult.error(404, 2, "No users found") and return
      else
        flash[:error] = _("No users found.")
      end
    else
      @permissions = {:groupsget => false, :useradd => false, :usermodify => false}
      @permissions[:usermodify] = true if permission_granted? "org.opensuse.yast.modules.yapi.users.usermodify"
      @permissions[:groupsget] = true if permission_granted? "org.opensuse.yast.modules.yapi.users.groupsget"
      @permissions[:useradd] = true if permission_granted? "org.opensuse.yast.modules.yapi.users.useradd"
      @users.each do |user|
        user.user_password2 = user.user_password
        user.uid_number	= user.uid_number
        user.grp_string = user.grouplist.keys.join(",")
        my_roles=[]
        all_roles=[]
	@roles= Role.find :all
        @roles.each do |role|
         if role.users.include?(user.id)
          my_roles.push(role.name)
         end
         all_roles.push(role.name)
        end if @roles

        user.roles_string = my_roles.join(",")
        @all_roles_string = all_roles.join(",")
	@groups = []
        if @permissions[:groupsget]
          @groups = Group.find :all
        end
	grps_list=[]
        @groups.each do |group|
	 grps_list.push(group.cn)
        end
        @all_grps_string = grps_list.join(",")
      end
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    yapi_perm_check "users.userget"
    if params[:id].blank?
      render ErrorResult.error(404, 2, "empty parameter") and return
    end

    begin
      # try to find the user, and 404 if it does not exist
      @user = User.find(params[:id])
      if @user.nil?
        render ErrorResult.error(404, 2, "user not found") and return
      end
    rescue Exception => e
      render ErrorResult.error(500, 2, e.message) and return
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    yapi_perm_check "users.useradd"
    @user = User.new( :id => :nil,
      :groupname	=> nil,
      :cn		=> nil,
      :grouplist	=> [],
      :allgroups	=> [],
      :home_directory	=> nil,
      :cn		=> nil,
      :uid		=> nil,
      :uid_number	=> nil,
      :login_shell	=> "/bin/bash",
      :user_password	=> nil,
      :user_password2	=> nil,
      :type		=> "local",
      :roles_string	=> ""
    )
    @all_roles_string = ""
    all_roles=[]
    @roles = Role.find :all
    my_roles=[]
    @roles.each do |role|
      all_roles.push(role.name)
    end if @roles
    @all_roles_string = all_roles.join(",")
    @all_users_string = all_users

    @groups = []
    if @permissions[:groupsget] == true
      @groups = Group.find :all
    end
    grp_list=[]
    @groups.each do |group|
     grp_list.push(group.cn)
    end
    @all_grps_string = grp_list.join(",")
    
    @user.grp_string = ""
  end


  # GET /users/1/edit
  def edit
    yapi_perm_check "users.usermodify"
    @user = User.find(params[:id])
    @groups = Group.find(:all)

    #FIXME handle if id is invalid

    @user.type	= ""
    @user.id	= @user.uid # use id for storing index value (see update)
    @user.grp_string = ""

    @all_grps_string = ""

    # FIXME hack, this must be done properly
    # (my keys in camelCase were transformed to under_scored)
    # XXX this looks like code which do nothing!!!
#    @user.uid_number	= @user.uid_number
#    @user.home_directory	= @user.home_directory
#    @user.login_shell	= @user.login_shell
#    @user.user_password	= @user.user_password
#    @user.user_password2= @user.user_password

    @user.grouplist.each do |group|
       if @user.grp_string.blank?
          @user.grp_string = group.cn
       else
          @user.grp_string += ",#{group.cn}"
       end
    end
    @groups.each do |group|
       if @all_grps_string.blank?
          @all_grps_string = group.cn
       else
          @all_grps_string += ",#{group.cn}"
       end
    end
  end


  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    yapi_perm_check "users.useradd"
    error = nil
    begin
      @user = User.create(params[:users])
      if @user.roles_string!=nil
        save_roles(@user.id,@user.roles_string)
      end
    rescue Exception => error
      logger.error(error.message)
    end

    if error
      respond_to do |format|
        format.xml  { render ErrorResult.error(404, 2, error.message) }
        format.json { render ErrorResult.error(404, 2, error.message) }
        format.html { flash[:error] = YaST::ServiceResource.error(error) 
                      render :action => "new"
                    }
      end
    else
      respond_to do |format|
        format.xml  { render :show }
        format.json { render :show }
        format.html { flash[:notice] = _("User <i>%s</i> was successfully created.") % @user.uid
                      redirect_to :action => "index"
                    }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    yapi_perm_check "users.usermodify"
    error = nil
    begin
      begin
        @user = User.find(params[:id])
      rescue Exception => error
        logger.error(error.message)
      end
      unless error
        if params["user"]["roles_string"]!=nil
          save_roles(@user.id,params["user"]["roles_string"])
        end
        @user.load_attributes(params[:user])
        @user.type = "local"
        @user.save(params[:id])
      end
    rescue Exception => error
      logger.error(errot.message)
    end    
    if error
      respond_to do |format|
        format.xml  { render ErrorResult.error(404, 2, error.message) }
        format.json { render ErrorResult.error(404, 2, error.message) }
        format.html { flash[:error] = YaST::ServiceResource.error(error) 
                      render :action => "index"
                    }
      end
    else
      respond_to do |format|
        format.xml  { render :show }
        format.json { render :show }
        format.html { flash[:notice] = _("User <i>%s</i> was successfully updated.") % @user.uid
                      redirect_to :action => "index"
                    }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json
  def destroy
    yapi_perm_check "users.userdelete"

    begin
      @user = User.find(params[:id])
      @user.destroy
    rescue Exception => e
      respond_to do |format|
        format.xml  { render ErrorResult.error(404, 2, error.message) }
        format.json { render ErrorResult.error(404, 2, e.message) }
        format.html { flash[:error] = _("Error: Could not remove user <i>%s</i>.") % @user.uid 
                      render :action => "index"
                    }
       end
       return
    end
    respond_to do |format|
      format.xml  { render :show }
      format.json { render :show }
      format.html { flash[:notice] = _("User <i>%s</i> was successfully removed.") % @user.uid
                    redirect_to :action => "index"
                  }
      end
  end

end

