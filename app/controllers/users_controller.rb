class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]
  # before_action :authuser, only: [:index,:show,:updatepw,:updatemail,:companyuser]
  
  before_action :authuser, except: [:createnewuser,:logout,:login]
  layout "home" 
  
  require "azure"
  
  require 'rubygems'
  require 'mongo'
  
  def portfolio
    
  end
  
  def tracking
    
  end
  
  def account
    @current_user_network = @db[:network].find('company_id' => @user_company_id)
    @db.close
  end
  
  
  def edituser
    
      if @user_role == "read"
        data = {:message => "You cant delete anything", :status => "false"}
        return render :json => data, :status => :ok
      end
    
      user_id = params[:id]
      user = @db[:user].find('id' => user_id.to_i)
      
      if user.count.to_i != 1
          data = {:message => "Wrong input", :status => "false"}
          return render :json => data, :status => :ok
      else
        
          @update_name =  params[:signup_name]
          @update_email =  params[:signup_email]
          @update_password =  params[:signup_password]
          @update_user_role =  params[:user_role]
          
          if @user_role == "read"
              data = {:message => "You can't edit anything", :status => "false"}
              return render :json => data, :status => :ok 
          end
          
          
          if @update_password.to_s != ""
              @encrypted_password = BCrypt::Password.create(@update_password.to_s)
              @db[:user].find('id' => user_id.to_i).update_one('$set'=> { 'password' => @encrypted_password })
          end
          
          @db[:user].find('id' => user_id.to_i).update_one('$set'=> { 'email' => @update_email, 'username' => @update_name, 'role' => @update_user_role })
          @db.close
          
          data = {:message => "Done", :status => "true", :user => user}
          return render :json => data, :status => :ok 
          
      end
  end
  
  
  def switchuserstatus
    
      if @user_role == "read"
        data = {:message => "You cant edit anything", :status => "false"}
        return render :json => data, :status => :ok
      end
    
      user_id = params[:id]
      user_status = params[:status]
      
      user = @db[:user].find('id' => user_id.to_i)
      @db.close
      
      if user.count.to_i != 1
          data = {:message => "Wrong input", :status => "false"}
          return render :json => data, :status => :ok
      else
          @db[:user].find('id' => user_id.to_i).update_one('$set'=> { 'status' => user_status.to_s })
          @db.close
          
          data = {:message => "Done", :status => "true"}
          return render :json => data, :status => :ok 
      end
  end
  
  
  def getuser
    
      if @user_role == "read"
        data = {:message => "You cant edit anything", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      user_id = params[:id]
      sub_users = @db[:user].find('id' => user_id.to_i)
      @db.close
      
      if sub_users.count.to_i != 1
          data = {:message => "Wrong input", :status => "false"}
          return render :json => data, :status => :ok
      else          
          data = {:message => "Done", :status => "true", :user => sub_users}
          return render :json => data, :status => :ok 
      end
  end
  
  
  def user
    
    @current_user.each do |user|
      @current_user_password = user["password"]
      @userid = user["id"]
      @company_id = user["company_id"] 
    end
    
    @sub_users = @db[:user].find('company_id' => @company_id)
    @db.close
    
  end
  
  
  def updatepw
    
    @input_current_pw =  params[:up_c_password]
    @input_new_pw =  params[:up_n_password]
    
    @current_user.each do |user|
      @current_user_password = user["password"]
      @id = user["id"]
    end
    
    @encrypted_password = BCrypt::Password.new(@current_user_password)
    @auth = (@encrypted_password == @input_current_pw)
    
    if @auth == false
      data = {:message => "Current PW not correct", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @encrypted_password = BCrypt::Password.create(@input_new_pw.to_s)
    
    @db[:user].find('id' => session[:user_id]).update_one('$set'=> { 'password' => @encrypted_password })
    @db.close
    @db[:user].find('id' => session[:user_id]).update_one('$set'=> { 'last_login' => @now })
    @db.close
    
    data = {:message => "PW Updated", :status => "true"}
    return render :json => data, :status => :ok
  end
  
  
  
  
  
  def updatemail
    #put logout here to avoid hack, this function is not in use for now
    
    session[:user_id] = nil
    return redirect_to "/"
    # @input_current_pw =  params[:um_c_password]
    # @input_new_email =  params[:um_n_mail]
#    
    # @current_user.each do |user|
      # @current_user_password = user["password"]
      # @id = user["id"]
    # end
#    
    # @encrypted_password = BCrypt::Password.new(@current_user_password)
    # @auth = (@encrypted_password == @input_current_pw)
#     
    # if @auth == false
      # data = {:message => "Current PW not correct"}
      # return render :json => data, :status => :ok
    # end
#     
    # @db[:user].find('id' => session[:user_id]).update_one('$set'=> { 'password' => @input_new_email })
  end
  
  
  
  def createcompany
  end
  
  
  
  
  
  def removeuser
    
    
    if @user_role != "super"
      # session[:user_id] = nil
      # return redirect_to "/"
      data = {:message => "You cant remove anything", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @id =  params[:remove_userid]
    @db[:user].find('id' => @id.to_i).delete_one
    @db.close
    # @result = @db[:user].find('id' => @id)
    
    @db[:network_user].find('user' => @id.to_i).delete_many
    @db.close
    
    data = {:message => "Removed", :status => "true", :id => @id}
    return render :json => data, :status => :ok
  end
  
  def createnewuser
    # Mongoid.database.connection.close 
    last_user_id = get_last_id("user")
    last_company_id = get_last_id("company")
    
    @username =  params[:signup_name]
    
    @email =  params[:signup_email]
    @password = params[:signup_password]
    
    @encrypted_password = BCrypt::Password.create(@password.to_s)

    @user_role = params[:user_role]
    @company_role = params[:company_role]
    
    @company = params[:signup_company]
    @user_company_id = params[:signup_company_id]
    
    @sub_user = params[:sub_user]
    
    
    current_user = @db[:user].find('email' => @email.to_s)
    @db.close
    current_company = @db[:company].find('name' => @company.to_s)
    @db.close
    
    if current_company.count == 1
      data = {:message => "This Company exist, can't use this name", :status => "false"}
      return render :json => data, :status => :ok
    end
     
    if current_user.count == 1
      data = {:message => "This user exist, use another email", :status => "false"}
      return render :json => data, :status => :ok      
    else
      
      @user_id = last_user_id.to_i + 1
      @company_id = last_company_id.to_i + 1
      
      if @user_company_id.nil?
          @user_company_id = @company_id
      end
      
      if @username.nil?
          @username = @email
      end
      
      if !@user_role.nil?
        @db[:user].insert_one({ id: @user_id.to_i, company_id: @user_company_id.to_i, email: @email, username: @username, password: @encrypted_password, role: @user_role.to_s, status: 'start', create_date: @now, last_login: @now })
        @db.close
        update_last_id("user",@user_id)
      end
      
      if !@company_role.nil?
        @db[:company].insert_one({ id: @company_id.to_i, name: @company.to_s, user_id: @user_id, role: @company_role.to_s, status: 'start', create_date: @now })
        @db.close
        update_last_id("company",@company_id)
      end
      
      if @sub_user.to_i == 0
          session[:user_id] = @user_id
          session[:user_role] = @user_role.to_s
      end 
           
      data = {:message => "Add User Done", :user_id => @user_id, :company_id => @company_id, :status => "true"}
      return render :json => data, :status => :ok
      
    end
  end
  
  def logout
    session[:user_id] = nil
    session[:user_network_id_array] = nil
    return redirect_to "/"
  end
  
  
  def login
    session[:user_network_id_array] = nil
    @email =  params[:login_email]
    @password = params[:login_password]
    
    if params[:login_email].nil?
      data = {:message => "Input email empty", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    if params[:login_password].nil?
      data = {:message => "Input password empty", :status => "false"}
      return render :json => data, :status => :ok  
    end
    
    
    @current_user = @db[:user].find('email' => @email)
    @db.close
    @current_user_count = @current_user.count.to_i
    
    if @current_user_count == 0
      data = {:message => "This user was not found in the system.", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    if @current_user_count > 1
      data = {:message => "Something Wrong with your Account, please call us.", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @current_user.each do |user|
      @current_user_password = user["password"]
      @id = user["id"]
    end
    
    @encrypted_password = BCrypt::Password.new(@current_user_password)
    @auth = (@encrypted_password == @password)
    
    # data = {:encrypted_password => @encrypted_password, :auth => @auth, :current_user_password => @current_user_password, :input_password => @password}
    # return render :json => data, :status => :ok
    
    if @auth != true
      data = {:message => "The password entered does not match the password for this account. Please try again.", :status => "false"}
      return render :json => data, :status => :ok
    end 
      
    @current_user.each do |user|
      @current_user_confirm_id = user["id"]
      @current_user_role = user["role"]
      @current_user_status = user["status"]
    end
    
    
    if @current_user_status.to_s != "start"
      data = {:message => "Your Account is Disable, Please contact your admin to enable it.", :status => "false"}
      return render :json => data, :status => :ok
    end 
      
    session[:user_id] = @current_user_confirm_id 
    session[:user_role] = @current_user_role.to_s
    
    
     
    @db[:user].find('email' => @email).update_one('$set'=> { 'last_login' => @now })
    @db.close
    
    data = {:message => "Logged In", :user_id => @current_user_confirm_id, :status => "true"}
    return render :json => data, :status => :ok 
    
    # cursor = db[:test].find('aaa' => { '$lt' => 5000 })
    # cursor.each do |doc|
      # concat doc
      # concat "<br /><br />".html_safe
    # end    
  end
  
  
  # GET /users
  # GET /users.json
  def index
      
  end
  

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    
    # def saltkey
      # @password_salt = BCrypt::Engine.generate_salt      
    # end
    
    # def db
      # @db = Mongo::Client.new([ '42.159.133.234:27017' ], :database => 'adeqo', :connect => :direct)
    # end
    
    
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params[:user]
    end
end
