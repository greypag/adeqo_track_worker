class NetworksController < ApplicationController
  before_action :set_network, only: [:show, :edit, :update, :destroy]
  before_action :authuser
  layout "home"
  
  # caches_page :campaigns
  # caches_action :getcampaigns
  
  
  def sogou_api(username,password,token,api_string)            
    @sogou_api = Savon.client(
      wsdl: "http://api.agent.sogou.com:80/sem/sms/v1/"+api_string+"?wsdl",
      pretty_print_xml: true,
      log: true,
      env_namespace: :soap,
      namespaces: {"xmlns:common" => "http://api.sogou.com/sem/common/v1"},
      soap_header: { 
        "common:AuthHeader" => {
          'common:token' => token,
          'common:username' => username,
          'common:password' => password
        }
      }
    )    
  end
  
  def threesixty_api( api_key, access_token, service, method, params = {})
    url = "https://api.e.360.cn/2.0/#{service}/#{method}"
      response = HTTParty.post(url,
            timeout: 300, 
            body: params,
            headers: {
                        'apiKey' => api_key, 
                        'accessToken' => access_token, 
                        'serveToken' => Time.now.to_i.to_s  
                      })
      
      @response = response                
      return response.parsed_response
  end
  
  def threesixty_api_login(username,password,api_key,api_secret)
    cipher_aes = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher_aes.encrypt
    cipher_aes.key = api_secret[0,16]
    cipher_aes.iv = api_secret[16,16]
    encrypted = (cipher_aes.update(Digest::MD5.hexdigest(password)) + cipher_aes.final).unpack('H*').join
    url = "https://api.e.360.cn/account/clientLogin"
    response = HTTParty.post(url,
        :timeout => 300,
        :body => {
        :username => username,
        :passwd => encrypted[0,64]
        },
        :headers => {'apiKey' => api_key }
    )
    return response.parsed_response
  end
  
  def bulkuploadedit
    
  end
  
  def bulkuploadadd
      
      
  end
  # def bulkjob
#     
      # file = params[:file]
      # @upload_type = params[:upload_type]
      # @account_id = params[:account]
      # @status = params[:status]
#       
      # begin
          # xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      # rescue Exception
          # # return render :text => "File type error, Exexl File(.xlsx) only."
          # data = {:message => "File type error, Exexl File(.xlsx) only.", :status => "false", :sdsf => @upload_type}
          # return render :json => data, :status => :ok
      # end
#       
      # data = {:message => "Your Request is invalid.", :status => "false", :sdsf => @upload_type}
      # return render :json => data, :status => :ok
  # end
  def resumebulkjob
      @_id = params[:_id]
      
      @current_jobs = @db2["bulkjob"].find('_id' => BSON::ObjectId.from_string(@_id.to_s)).update_one('$set'=> { 'status' => 0, 'last_update' => @now})
      @db2.close
      
      if @current_jobs.count.to_i > 0
          data = {:message => "Your Request is complete.", :status => "true"}
      else
          data = {:message => "Your Request is invalid.", :status => "false"}
      end
      return render :json => data, :status => :ok
  end
  
  
  def cancelbulkjob
      @_id = params[:_id]
      
      @current_jobs = @db2["bulkjob"].find('_id' => BSON::ObjectId.from_string(@_id.to_s)).update_one('$set'=> { 'status' => 5, 'last_update' => @now})
      @db2.close
      
      if @current_jobs.count.to_i > 0
          data = {:message => "Your Request is complete.", :status => "true"}
      else
          data = {:message => "Your Request is invalid.", :status => "false"}
      end
      return render :json => data, :status => :ok
  end
  
  
  def getadvancesearch
      
      csv_array = []     
      data_array = []
      network_id_list = []
      network_list_hash = Hash.new()
      @draw = params[:draw]
      @length = params[:length]
      @skip_data = params[:start]
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @csv = params[:csv]
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      @order = params[:order]
      
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = request_start_date
          @end_date = request_start_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      else
          session[:adv_end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date
          @end_date = @end_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      end
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      


      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"
      else
          session[:adv_start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date
          @start_date = @start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"
      end
      
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"


      @channel_array = params[:channel_array]
      @filter_account_array = params[:account_array]
      @user_network_array = []

      if !@filter_account_array.nil?
          @filter_account_array.each do |filter_network|
              @user_network_array << filter_network.to_i
          end
      else
          @user_network = @db[:network_user].find('user' => session[:user_id].to_i)
          @db.close
          
          @user_network.each do |user_network|
              @user_network_array << user_network["network_id"]
          end
      end

      @user_network_array.each do |usernetwork|
          @total_network = @db[:network].find('id' => usernetwork,'type' => { "$in" => @channel_array})
          @db.close
          @total_network.each do |network_d|
            network_id_list.push(network_d["id"])
          end
      end

      @network = @db[:network].find('type' => { "$in" => @channel_array})
      @network.each do |network_d|
        network_list_hash[network_d['id'].to_s] = network_d['name'].to_s
      end
      
      @advancesearchjob = @db[:advancesearchjob].find('request_date'  => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s },'network_id' => {"$in" => network_id_list}).sort({ request_date: -1 })
      @db.close
      
      recordsTotal = @advancesearchjob.count.to_i
      
      if @advancesearchjob.count.to_i > 0 
        
          @advancesearchjob.each do |advancesearchjob_d|

          filter_object = ""
          filter_object_csv = ""

          if advancesearchjob_d["filter_object"].to_s != ""
                          
            advancesearchjob_d["filter_object"].each do |filter|
              filter_e =  eval(filter[1].to_s)
              name = filter_e["name"]
              rule = filter_e["rule"]
              value = filter_e["value"]
                            
              name = name.slice(0,1).capitalize + name.slice(1..-1)
              rule = rule.to_s.gsub("**", 'contain')
                            
              filter_object = filter_object + name.to_s + " " + rule.to_s + " " + value.to_s + "<br>"
              filter_object_csv = filter_object_csv + name.to_s + " " + rule.to_s + " " + value.to_s + "\n"
              #filter_object = filter_object + "<br>"
            end                     
          end
          job_process = ''
          if advancesearchjob_d["process"].to_i == 0 then
            job_process = 'Pending'
          elsif advancesearchjob_d["process"].to_i == 1 then
            job_process = 'Processing'
          elsif advancesearchjob_d["process"].to_i == 2 then
            job_process = 'Done'
          elsif advancesearchjob_d["process"].to_i == 3 then
            job_process = 'Cancel'
          end


          csv_array << [advancesearchjob_d['network_id'],network_list_hash[advancesearchjob_d['network_id'].to_s],advancesearchjob_d['apply_level'],advancesearchjob_d['start_date'],advancesearchjob_d['end_date'],advancesearchjob_d['edit_status'],advancesearchjob_d['action'],filter_object_csv,job_process,advancesearchjob_d['request_date']]
          data_array  << [advancesearchjob_d['network_id'],network_list_hash[advancesearchjob_d['network_id'].to_s],advancesearchjob_d['apply_level'],advancesearchjob_d['start_date'],advancesearchjob_d['end_date'],advancesearchjob_d['edit_status'],advancesearchjob_d['action'],filter_object,job_process,advancesearchjob_d['msg'].to_s,advancesearchjob_d['request_date'],advancesearchjob_d['last_update'],advancesearchjob_d['_id'].to_s]
        end
      end

      if @csv.to_i == 1
          if @export_csv_start_date == @export_csv_end_date then
            @filename = "advance_search_job_" + @export_csv_start_date 
          else
            @filename = "advance_search_job_" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
          end
          head = ["\xEF\xBB\xBFNetwork ID", "\xEF\xBB\xBFNetwork Name", "\xEF\xBB\xBFApply Level", "\xEF\xBB\xBFFrom", "To", "Job","Action", "Filter", "Process", "Request Date"]
          # csv(@filename,head,csv_array)
          excel(@filename,head,csv_array)
      else
        
          if !@order.nil?
              @sort_column = @order["0"]["column"]
              @sort_method = @order["0"]["dir"]
            
              if @sort_method.to_s == "asc" then
                data_array = data_array.sort_by{|k|k[@sort_column.to_i]}      
              else
                data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
              end
          end        
          @data = {
                  :draw => @draw,
                  :recordsTotal => recordsTotal,
                  :recordsFiltered => data_array.count.to_i,
                  :data => data_array.drop(@skip_data.to_i).first(@length.to_i),
                  # :data => data_array,
                  # :data => [],
                  :status => "true"
          }
          return render :json => @data, :status => :ok      
      end
    
  end
  
  
  def canceladvancesearchjob
      @_id = params[:_id]
      
      @current_jobs = @db["advancesearchjob"].find('_id' => BSON::ObjectId.from_string(@_id.to_s)).update_one('$set'=> { 'process' => 3, 'last_update' => @now})
      @db.close
      
      if @current_jobs.count.to_i > 0
          data = {:message => "Your Request is complete.", :status => "true"}
      else
          data = {:message => "Your Request is invalid.", :status => "false"}
      end
      return render :json => data, :status => :ok
  end
  
  def advancesearchjob
    
      @account_id = params[:account]
      @apply_level = params[:page]
      
      @date_range = params[:date_range]
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      
      #campign only has status
      @campaign_status = params[:campaign_status]
      #campign only has status
      
      #other level has status and other option      
      @adgroup_action_type = params[:adgroup_action_type]
      @adgroup_action_value = params[:adgroup_action_value]
      @adgroup_action_classifier = params[:adgroup_action_classifier]
      
      @adgroup_find_and_replace = params[:adgroup_find_and_replace]
      @adgroup_find_and_replace_value = params[:adgroup_find_and_replace_value]
      @adgroup_find_and_replace_find = params[:adgroup_find_and_replace_find]
      
      @ad_action_type = params[:ad_action_type]
      @ad_action_value = params[:ad_action_value]
      @ad_action_classifier = params[:ad_action_classifier]
      
      @ad_find_and_replace = params[:ad_find_and_replace]
      @ad_find_and_replace_value = params[:ad_find_and_replace_value]
      @ad_find_and_replace_find = params[:ad_find_and_replace_find]
      
      @keyword_action_type = params[:keyword_action_type]
      @keyword_action_value = params[:keyword_action_value]
      @keyword_action_classifier = params[:keyword_action_classifier]
      
      @keyword_find_and_replace = params[:keyword_find_and_replace]
      @keyword_find_and_replace_value = params[:keyword_find_and_replace_value]
      @keyword_find_and_replace_find = params[:keyword_find_and_replace_find]
      #other level has status and other option
      
      @action = params[:happens]
      @filter_object = params[:filter_object]
      @type = params[:type]
      
      
      
      if @account_id.to_s == "" || @start_date.to_s == "" || @end_date.to_s == ""
          data = {:message => "Missing Data, Try again.", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      port_array = [81,83]
      # port_array = [81,83,85,87]
      random_port = port_array.shuffle.sample

      if @apply_level.to_s == "Campaign"
          if !@filter_object.nil?
              @filter_object.each do |filter_object|
                
                  if filter_object[1]['value'].to_s == ""
                      data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                
                  if filter_object[1]['name'].downcase.to_s != "campaign_name" && filter_object[1]['name'].downcase.to_s != "status"
                      if !filter_object[1]['value'].match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
                          data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                          return render :json => data, :status => :ok
                      end
                  end
              end
          end
          
          
          
          @db["advancesearchjob"].insert_one({ 
                                        network_id: @account_id.to_i,
                                        network_type: @type.to_s,
                                        user_email: @current_user_email.to_s,
                                        
                                        apply_level: @apply_level.to_s, 
                                        date_range: @date_range.to_s,
                                        start_date: @start_date.to_s,
                                        end_date: @end_date.to_s,
                                        
                                        edit_status: @campaign_status.to_s, 
                                        
                                        worker: random_port.to_i, 
                                        
                                        action: @action.to_s,
                                        filter_object: @filter_object,
                                        process: 0,
                                        request_date: @now                                            
                                        })
          @db.close
        
      
      
      elsif @apply_level.to_s == "Ad Groups"
        
        
          if @adgroup_action_type.to_s.include?("cpc")
              if @adgroup_action_value.to_s == ""
                  data = {:message => "Please specify the “max. CPC” value. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              elsif !@adgroup_action_value.to_s.match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
                  data = {:message => "CPC Value Invalid, please check", :status => "false"}
                  return render :json => data, :status => :ok
              end
              
              if !@adgroup_action_type.to_s.include?("set") && @adgroup_action_value.to_s == "0"
                  data = {:message => "CPC Value Invalid, please check", :status => "false"}
                  return render :json => data, :status => :ok
              end  
          end
          
          if @adgroup_action_type.to_s == "find_and_replace"
              if @adgroup_find_and_replace_value.to_s == ""
                  data = {:message => "Please specify the “Replace” string. This field cannot be left empty", :status => "false"}
                  return render :json => data, :status => :ok
              elsif @adgroup_find_and_replace_find.to_s == ""
                  data = {:message => "Please specify the “Find” string. This field cannot be left empty", :status => "false"}
                  return render :json => data, :status => :ok  
              elsif @adgroup_find_and_replace_value.to_s == @adgroup_find_and_replace_find.to_s
                  data = {:message => "Can't Replace the same Value.", :status => "false"}
                  return render :json => data, :status => :ok  
              end
          end
          
          if !@filter_object.nil?
              @filter_object.each do |filter_object|
                
                  if filter_object[1]['value'].to_s == ""
                      data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                
                  if filter_object[1]['name'].downcase.to_s != "adgroup_name" && filter_object[1]['name'].downcase.to_s != "status"
                      if !filter_object[1]['value'].match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
                          data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                          return render :json => data, :status => :ok
                      end
                  end
              end
          end
          
          
          insert = {}
          insert[:network_id] = @account_id.to_i
          insert[:network_type] = @type.to_s
          insert[:user_email] = @current_user_email.to_s
          insert[:apply_level] = @apply_level.to_s
          insert[:date_range] = @date_range.to_s
          insert[:start_date] = @start_date.to_s
          insert[:end_date] = @end_date.to_s
          
          if @adgroup_action_type.to_s == "active" || @adgroup_action_type.to_s == "inactive"
              insert[:edit_status] = @adgroup_action_type.to_s
          end
          
          if @adgroup_action_type.to_s.include?("cpc")
              insert[:action_type] = @adgroup_action_type.to_s
              insert[:action_value] = @adgroup_action_value.to_s
              insert[:action_classifier] = @adgroup_action_classifier.to_s
          end
          
          if @adgroup_action_type.to_s == "find_and_replace"
              insert[:action_type] = @adgroup_action_type.to_s
              insert[:find_and_replace_name] = @adgroup_find_and_replace.to_s
              insert[:find_and_replace_find] = @adgroup_find_and_replace_find.to_s
              insert[:find_and_replace_value] = @adgroup_find_and_replace_value.to_s
          end
          
          insert[:action] = @action.to_s
          insert[:filter_object] = @filter_object
          insert[:process] = 0
          insert[:worker] = random_port.to_i
          insert[:request_date] = @now
          
          @db["advancesearchjob"].insert_one(insert)
          @db.close
      
      
      
      elsif @apply_level.to_s == "Ads"
        
          if @ad_action_type.to_s == "find_and_replace"
              if @ad_find_and_replace_value.to_s == ""
                  data = {:message => "Please specify the “Replace” string. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              elsif @ad_find_and_replace_find.to_s == ""
                  data = {:message => "Please specify the “Find” string. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              elsif @ad_find_and_replace_value.to_s == @ad_find_and_replace_find.to_s
                  data = {:message => "Can't Replace the same Value", :status => "false"}
                  return render :json => data, :status => :ok   
              end
          end
          
          if !@filter_object.nil?
              @filter_object.each do |filter_object|
                
                  if filter_object[1]['value'].to_s == ""
                      data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                
                  if filter_object[1]['name'].downcase.to_s != "adgroup_name" && filter_object[1]['name'].downcase.to_s != "status" && filter_object[1]['name'].downcase.to_s != "headline" && filter_object[1]['name'].downcase.to_s != "desc_1" && filter_object[1]['name'].downcase.to_s != "desc_2" && filter_object[1]['name'].downcase.to_s != "display_url" && filter_object[1]['name'].downcase.to_s != "final_url" && filter_object[1]['name'].downcase.to_s != "m_display_url" && filter_object[1]['name'].downcase.to_s != "m_final_url"
                      if !filter_object[1]['value'].match(/\A[-+]?[0-9]*\.?[0-9]+\Z/) 
                          data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                          return render :json => data, :status => :ok
                      end
                  end
              end
          end
          
          
          insert = {}
          insert[:network_id] = @account_id.to_i
          insert[:network_type] = @type.to_s
          insert[:user_email] = @current_user_email.to_s
          insert[:apply_level] = @apply_level.to_s
          insert[:date_range] = @date_range.to_s
          insert[:start_date] = @start_date.to_s
          insert[:end_date] = @end_date.to_s
          
          if @ad_action_type.to_s == "active" || @ad_action_type.to_s == "inactive"
              insert[:edit_status] = @ad_action_type.to_s
          end
          
          if @ad_action_type.to_s == "find_and_replace"
              insert[:action_type] = @ad_action_type.to_s
              insert[:find_and_replace_name] = @ad_find_and_replace.to_s
              insert[:find_and_replace_find] = @ad_find_and_replace_find.to_s
              insert[:find_and_replace_value] = @ad_find_and_replace_value.to_s
          end
          
          insert[:action] = @action.to_s
          insert[:filter_object] = @filter_object
          insert[:process] = 0
          insert[:worker] = random_port.to_i
          insert[:request_date] = @now
          
          @db["advancesearchjob"].insert_one(insert)
          @db.close
      
      elsif @apply_level.to_s == "Keywords"
        
          if @keyword_action_type.to_s.include?("cpc")
              if @keyword_action_value.to_s == ""
                  data = {:message => "Please specify the “max. CPC” value. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              # elsif !@keyword_action_value.to_s.match(/^(\d)+$/)
              elsif !@keyword_action_value.to_f == 0
                  data = {:message => "CPC Value invalid, please check", :status => "false"}
                  return render :json => data, :status => :ok
              end  
              
              if !@keyword_action_type.to_s.include?("set") && @keyword_action_value.to_s == "0"
                  data = {:message => "CPC Value Invalid, please check", :status => "false"}
                  return render :json => data, :status => :ok
              end
          end
          
          if @keyword_action_type.to_s == "find_and_replace"
              if @keyword_find_and_replace_value.to_s == ""
                  data = {:message => "Please specify the “Replace” string. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              elsif @keyword_find_and_replace_find.to_s == ""
                  data = {:message => "Please specify the “Find” string. This field cannot be left empty.", :status => "false"}
                  return render :json => data, :status => :ok
              elsif @keyword_find_and_replace_value.to_s == @keyword_find_and_replace_find.to_s
                  data = {:message => "Can't Replace the same Value", :status => "false"}
                  return render :json => data, :status => :ok  
              end
          end
          
          if !@filter_object.nil?
              @filter_object.each do |filter_object|
                
                  if filter_object[1]['value'].to_s == ""
                      data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                
                  if filter_object[1]['name'].downcase.to_s != "adgroup_name" && filter_object[1]['name'].downcase.to_s != "status" && filter_object[1]['name'].downcase.to_s != "final_url" && filter_object[1]['name'].downcase.to_s != "m_final_url"
                      if !filter_object[1]['value'].match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
                          data = {:message => "Your "+filter_object[1]['name'].upcase.to_s+" input data is invalid, please check", :status => "false"}
                          return render :json => data, :status => :ok
                      end
                  end
              end
          end
          
          insert = {}
          insert[:network_id] = @account_id.to_i
          insert[:network_type] = @type.to_s
          insert[:user_email] = @current_user_email.to_s
          insert[:apply_level] = @apply_level.to_s
          insert[:date_range] = @date_range.to_s
          insert[:start_date] = @start_date.to_s
          insert[:end_date] = @end_date.to_s
          
          if @keyword_action_type.to_s == "active" || @keyword_action_type.to_s == "inactive"
              insert[:edit_status] = @keyword_action_type.to_s
          end
          
          if @keyword_action_type.to_s.include?("cpc")
              insert[:action_type] = @keyword_action_type.to_s
              insert[:action_value] = @keyword_action_value.to_s
              insert[:action_classifier] = @keyword_action_classifier.to_s
          end
          
          if @keyword_action_type.to_s == "find_and_replace"
              insert[:action_type] = @keyword_action_type.to_s
              insert[:find_and_replace_name] = @keyword_find_and_replace.to_s
              insert[:find_and_replace_find] = @keyword_find_and_replace_find.to_s
              insert[:find_and_replace_value] = @keyword_find_and_replace_value.to_s
          end
          
          insert[:action] = @action.to_s
          insert[:filter_object] = @filter_object
          insert[:process] = 0
          insert[:worker] = random_port.to_i
          insert[:request_date] = @now
          
          @db["advancesearchjob"].insert_one(insert)
          @db.close
      
      
      else
          data = {:message => "The Search Level incorrect.", :status => "false"}
          return render :json => data, :status => :ok 
      end
      
      data = {:message => "Your request has been placed in the queue. You will receive a notification email when this request is completed.", :status => "false"}
      return render :json => data, :status => :ok
  end
  
  
  
  def allupdatecampaign
      id_array = params[:item_id]
      status = params[:status]

      network_array = []
      array_array = []
      
      @network_type = params[:type]
      @account_id = params[:account]
      @action_type = params[:action_type]
      
      if id_array.nil? || status.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end

      begin
          update_msg_array = []
          
          if id_array.count.to_i > 0
              id_array = id_array.sort
              temp_network_id = 0
              temp_network_type = ""
              login = 0
              
              id_array.each do |id_array_d|
                  id_array_d_array = id_array_d.split("|")
                  
                  if id_array_d_array[0].to_i != temp_network_id.to_i
                      login = 0
                      temp_network_id = id_array_d_array[0].to_i
                      temp_network_type = id_array_d_array[1].to_s
                       
                      @network = @db[:network].find(id: temp_network_id.to_i)
                      @db.close
                      
                      if @network.count.to_i > 0
                          @network.each do |network_d|
                  
                              if temp_network_type == "sogou"
                                  @network.each do |network_d|
                                      # # @logger.info network_d['id'].to_s
                                      sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                                      sogou_result = @sogou_api.call(:get_account_info)
                                      
                                      if sogou_result.header[:res_header][:desc].to_s == "success"
                                          login = 1
                                          @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                                          if @remain_quote.to_i <= 500
                                              update_msg_array << "Sogou Account " + network_d["name"] + " doesn't have enough quota."
                                          else
                                              sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcPlanService")
                                          end
                                      else
                                          login = 0
                                          @remain_quote = 0
                                          update_msg_array << "Sogou Account " + network_d["name"].to_s + " " + @header[:res_header][:failures][:message].to_s
                                      end
                                  end
                              end
                            
                            
                              if temp_network_type == "360"
                                    @network.each do |network_d|
                                        @username = network_d["username"]
                                        @password = network_d["password"]
                                        @apitoken = network_d["api_token"]
                                        @apisecret = network_d["api_secret"]
                                                             
                                        login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                                        @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                                        
                                        if !@refresh_token.nil?
                                            login = 1
                                            @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                                            
                                            @remain_quote = @response.headers["quotaremain"].to_i
                                            if @remain_quote.to_i <= 500
                                                update_msg_array << "360 Account " + network_d["name"] + " doesn't have enough quota."
                                            end
                                        else
                                            login = 0
                                            @remain_quote = 0
                                            update_msg_array << "360 Account " + network_d["name"].to_s + " " + login_info["account_clientLogin_response"]["failures"]["item"]["message"].to_s
                                        end
                                    end
                              end
                          end
                      end
                  end
                  
                  if login == 1
                      if temp_network_type == "sogou"
                            
                              pause = nil                                
                              if status.to_s == "inactive"
                                  db_status = 12
                                  pause = "true"
                              end
                              if status.to_s == "active"
                                  pause = "false"
                                  db_status = 11
                              end
                              
                              # @logger.info @remain_quote
                              
                              if @remain_quote.to_i <= 500
                                    update_msg_array << id_array_d_array[3].to_s + " is not updated. Quota not enough."
                              else
                                    requesttypearray = []
                                    requesttype = {}
                                                                   
                                    requesttype[:cpcPlanId]    =  id_array_d_array[2].to_i
                                    requesttype[:pause]    =  pause
                                         
                                    requesttypearray << requesttype
                                         
                                    @update_status = @sogou_api.call(:update_cpc_plan, message: { cpcPlanTypes: requesttypearray })
                                    @header = @update_status.header.to_hash
                                    @msg = @header[:res_header][:desc]
                                    @remain_quote = @header[:res_header][:rquota]
                                    
                                    # # @logger.info @remain_quote
                                    # @return_num =  @header[:res_header][:oprs]
                                    # @update_status_body = @update_status.body.to_hash
                                    
                                    if @msg.to_s.downcase == "success"
                                        update_msg_array << id_array_d_array[3].to_s + " update Success."
                                        
                                        @db["all_campaign"].find('cpc_plan_id' => id_array_d_array[2].to_i,'network_type' => "sogou").update_one('$set'=> { 'status' => db_status.to_i })
                                        @db.close
                                    else  
                                        update_msg_array << id_array_d_array[3].to_s + " is not updated." + @header[:res_header][:failures][:message].to_s
                                    end
                              end
                      end
                      
                      
                      if temp_network_type == "360"
                              if status.to_s == "inactive"
                                  status_360 = "pause"
                                  db_status = "暂停"
                                  db_sys_status = "推广计划暂停"
                              end
                              if status.to_s == "active"
                                  status_360 = "enable"
                                  db_status = "启用"
                                  db_sys_status = "有效"
                              end 
                              
                              # # @logger.info @remain_quote
                              
                              if @remain_quote.to_i <= 500
                                  update_msg_array << id_array_d_array[3].to_s + " is not updated. Quota not enough."
                              else
                                
                                  body = {}
                                  body[:id] = id_array_d_array[2].to_i
                                  body[:status] = status_360
                                  
                                  @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "campaign", "update", body)
                                  @affectedRecords = @update_res["campaign_update_response"]
                                  
                                  # # @logger.info @update_res
                                  @remain_quote = @response.headers["quotaremain"].to_i
                                  # # @logger.info @remain_quote
                                  
                                  if @update_res["campaign_update_response"]["failures"].nil?
                                      update_msg_array << id_array_d_array[3].to_s + " update Success.."
                                      @db["all_campaign"].find('campaign_id' => id_array_d_array[2].to_i).update_one('$set'=> { 'status' => db_status.to_s,'sys_status' => db_sys_status.to_s})    
                                      @db.close
                                  else
                                      update_msg_array << id_array_d_array[3].to_s + " is not updated." + @update_res["campaign_update_response"]["failures"]["item"]["message"].to_s
                                  end
                              end  
                      end
                  end
                  
                  
              end
          end
                
          data = {:message => "Complete. <br /><br />" + update_msg_array.join("<br />") + "<br /><br />Please Refresh to view latest update.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again a bit later.", :status => "true"}
      end
      return render :json => data, :status => :ok
  end
  
  
  
  def threesixtyupdateadgroup
    
      
      id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
      
      cpc_action_type = params[:action_type]
      cpc_value = params[:value]
      classifier = params[:classifier]
      
      status = params[:status]
      
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
      
      if status.to_s == "inactive"
          status = "pause"
          db_status = "暂停"
      end
      if status.to_s == "active"
          status = "enable"
          db_status = "启用"
      end
      
      if id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "threesixty"
        data = {:message => "Network Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      
      update_msg_array = []
      
      begin
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                    
                    @username = network_d["username"]
                    @password = network_d["password"]
                    @apitoken = network_d["api_token"]
                    @apisecret = network_d["api_secret"]
                                         
                    login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                    @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                    
                    if @refresh_token.nil?
                        data = {:message => "API Info not correct", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                    @remain_quote = @response.headers["quotaremain"].to_i
                    
                    if @remain_quote.to_i <= 500
                        data = {:message => "<p>360 Account " + network_d["name"] + " doesn't have enough quota.</p>", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    id_array.each do |id_array_d|
                      
                        real_id = id_array_d.split('|')
      
                        
                        if @remain_quote.to_i <= 500
                            update_msg_array << "Update Adgroup " + real_id[1].to_s + " failed. Not enough quota."
                        else
                            # ******************************************************set db name here
                            db_name = "adgroup_360_"+network_id.to_s
                            @adgroup = @db[db_name].find('adgroup_id' => real_id[0].to_i)
                            @db.close
                            # ******************************************************set db name here
                            
                            if @adgroup.count.to_i > 0
                                  @adgroup.each do |adgroup_d|
                                      @price = adgroup_d["price"]
                                      @adgroup_name = adgroup_d["adgroup_name"]
                                      
                                      @adgroup_name = @adgroup_name.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                      
                                      body = {}
                                      body[:id] = real_id[0].to_i
                                      
                                      if !replace_field.nil?
                                          if replace_field.to_s == "adgroup_name"
                                              body[:name] = @adgroup_name
                                          end
                                      end
                                      
                                      if !status.nil?
                                          body[:status] = status
                                      end
                                      
                                      if !cpc_action_type.nil?
                                          
                                          if cpc_action_type.to_s == "set"
                                              @new_price = cpc_value.to_f
                                              @new_price = @new_price.round(2)
                                              body[:price] = @new_price
                                          end
                                          
                                          if cpc_action_type.to_s == "increase"
                                              if classifier.to_s == "RMB"
                                                  @new_price = @price.to_f + cpc_value.to_f
                                                  @new_price = @new_price.round(2)
                                                  body[:price] = @new_price
                                              end
                                              
                                              if classifier.to_s == "%"
                                                  @new_price = @price.to_f + (@price.to_f*cpc_value.to_f)/100
                                                  @new_price = @new_price.round(2)
                                                  body[:price] = @new_price
                                              end
                                          end
                                          
                                          if cpc_action_type.to_s == "decrease"
                                              if classifier.to_s == "RMB"
                                                  @new_price = @price.to_f - cpc_value.to_f
                                                  @new_price = @new_price.round(2)
                                                  body[:price] = @new_price
                                              end
                                              
                                              if classifier.to_s == "%"
                                                  @new_price = @price.to_f - (@price.to_f*cpc_value.to_f)/100
                                                  @new_price = @new_price.round(2)
                                                  body[:price] = @new_price
                                              end
                                          end
                                          
                                      end
                                      
                                          
                                      @update_res = threesixty_api( network_d["api_token"].to_s, @refresh_token, "group", "update", body)
                                      @affectedRecords = @update_res["group_update_response"]
                                      
                                      @remain_quote = @response.headers["quotaremain"].to_i
                                      
                                      # @logger.info @affectedRecords
                                      # @logger.info @remain_quote
                                      
                                      if !@update_res["group_update_response"]["failures"].nil?
                                          update_msg_array << "Update Adgroup " + real_id[1].to_s + " failed. " + @update_res["group_update_response"]["failures"]["item"]["message"].to_s 
                                      else
                                          if !replace_field.nil?
                                              if replace_field.to_s == "adgroup_name"
                                                  update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "'name to "+ @adgroup_name.to_s + "Success."
                                                  @db[db_name].find('adgroup_id' => real_id[0].to_i).update_one('$set'=> { 'adgroup_name' => @adgroup_name.to_s })
                                                  @db.close
                                              end
                                          end
                                          
                                          if !status.nil?
                                              update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "' to "+ status.to_s + "Success."
                                              @db[db_name].find('adgroup_id' => real_id[0].to_i).update_one('$set'=> { 'status' => db_status.to_s })
                                              @db.close
                                          end
                                          
                                          if !cpc_action_type.nil?
                                              
                                              update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "' Price to "+ @new_price.to_s + "Success."
                                              @db[db_name].find('adgroup_id' => real_id[0].to_i).update_one('$set'=> { 'price' => @new_price.to_f })
                                              @db.close
                                              
                                          end 
                                      end
                                      
                                       
                                  end
                             end
                         end
                         
                    end
              end
          end
          
          data = {:message => "Complete. <br /><br />"+ update_msg_array.join("<br />")+"<br /><br />Please refresh to see the latest changes.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  def threesixtyupdatead
    
      ad_id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
      
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
      
      status = params[:status]
      
      if status.to_s == "inactive"
          status = "pause"
          db_status = "暂停"
      end
      if status.to_s == "active"
          status = "enable"
          db_status = "启用"
      end
        
      if ad_id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "threesixty"
        data = {:message => "Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      
      update_msg_array = []
      begin    
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                    
                    @username = network_d["username"]
                    @password = network_d["password"]
                    @apitoken = network_d["api_token"]
                    @apisecret = network_d["api_secret"]
                                         
                    login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                    @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                    
                    if @refresh_token.nil?
                        data = {:message => "API Info not correct", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                    @remain_quote = @response.headers["quotaremain"].to_i
                    
                    if @remain_quote.to_i <= 500
                        data = {:message => "<p>360 Account " + network_d["name"] + " doesn't have enough quota.</p>", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    @tracking_type = network_d["tracking_type"].to_s
                    @ad_redirect = network_d["ad_redirect"].to_s
                    @keyword_redirect = network_d["keyword_redirect"].to_s
                    @company_id = network_d["company_id"].to_s
                    @cookie_length = network_d["cookie_length"].to_s
                  
                    ad_id_array.each do |ad_id_array_d|
                        
                        
                        replace_field_find = params[:field_find]
                        replace_field_replace = params[:field_replace]
                          
                        requesttypearray = []
                        real_id = ad_id_array_d.split("|")
                        @ad_id = real_id[0]
                        
                        if @remain_quote.to_i <= 500
                            update_msg_array << "Update Ad " + real_id[1].to_s + " failed. Not enough quota."
                        else
                            db_name = "ad_360_"+network_id.to_s 
                            @ad = @db[db_name].find('ad_id' => @ad_id.to_i)
                            @db.close
                            
                            if @ad.count.to_i > 0
                                  @ad.each do |ad_d|
                                      
                                      @title = ad_d["title"]
                                      @description = ad_d["description"]
                                      @display_url = ad_d["show_url"]
                                      @final_url = ad_d["visit_url"]
                                      @m_display_url = ad_d["mobile_show_url"] 
                                      @m_final_url = ad_d["mobile_visit_url"]
                                      
                                      if !replace_field.nil?
                                          if replace_field.to_s == "headline"
                                              @title = @title.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                              request_str = '{"id":'+@ad_id+',"title":"'+@title+'"}'
                                          end
                                          
                                          if replace_field.to_s == "desc_1"
                                              @description = @description.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                              request_str = '{"id":'+@ad_id+',"description1":"'+@description+'"}'
                                          end
                                          
                                          if replace_field.to_s == "display_url"
                                              if @display_url.include?(".adeqo.")
                                                  replace_field_find = CGI.escape(replace_field_find)
                                                  replace_field_replace = CGI.escape(replace_field_replace)
                                              end
                                              @display_url = @display_url.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                              request_str = '{"id":'+@ad_id+',"displayUrl":"'+@display_url+'"}'  
                                          end
                                          
                                          if replace_field.to_s == "final_url"
                                              if @final_url.include?(".adeqo.")
                                                  tmp_replace_field_find = CGI.escape(replace_field_find)
                                                  tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                              end
                                              @final_url = @final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                              
                                              if !@final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                  @temp_final_url = @final_url
                                                  
                                                  @final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                                  @final_url = @final_url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id={wordid}"
                                                  @final_url = @final_url + "&cookie="+@cookie_length.to_s
                                                  @final_url = @final_url + "&device=pc"
                                                  @final_url = @final_url + "&tv=v1&durl="+CGI.escape(@temp_final_url.to_s)
                                              end
                                            
                                              request_str = '{"id":'+@ad_id+',"destinationUrl":"'+@final_url+'"}'
                                          end
                                          
                                          if replace_field.to_s == "mobile_display_url"
                                              if @m_display_url.include?(".adeqo.")
                                                  tmp_replace_field_find = CGI.escape(replace_field_find)
                                                  tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                              end
                                              @m_display_url = @m_display_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                              request_str = '{"id":'+@ad_id+',"mobileDisplayUrl":"'+@m_display_url+'"}'
                                          end
                                          
                                          if replace_field.to_s == "mobile_final_url"
                                              if @m_final_url.include?(".adeqo.")
                                                  tmp_replace_field_find = CGI.escape(replace_field_find)
                                                  tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                              end
                                              
                                              @m_final_url = @m_final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                              
                                              if !@m_final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                  @temp_m_final_url = @m_final_url
                                                  
                                                  @m_final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                                  @m_final_url = @m_final_url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id={wordid}"
                                                  @m_final_url = @m_final_url + "&cookie="+@cookie_length.to_s
                                                  @m_final_url = @m_final_url + "&device=pc"
                                                  @m_final_url = @m_final_url + "&tv=v1&durl="+CGI.escape(@temp_m_final_url.to_s)
                                              end
                                              request_str = '{"id":'+@ad_id+',"mobileDestinationUrl":"'+@m_final_url+'"}'
                                          end
                                      end
                                                              
                                      if !status.nil?
                                          request_str = '{"id":'+@ad_id+',"status":"'+status+'"}'
                                      end
                                      
                                      requesttypearray << request_str
                                      request = '['+requesttypearray.join(",")+']'
                                      # # @logger.info request
                                      
                                      body = { 
                                          'creatives' => request
                                      }
                                      
                                      @update_res = threesixty_api( network_d["api_token"].to_s, @refresh_token, "creative", "update", body)
                                      @affectedRecords = @update_res["creative_update_response"]["affectedRecords"]
                                      @remain_quote = @response.headers["quotaremain"].to_i
                                      
                                      if !@update_res["creative_update_response"]["failures"].nil?
                                          update_msg_array << "Update '"+real_id[1].to_s+ "' failed. " + @update_res["creative_update_response"]["failures"]["item"]["message"]
                                      else
                                          if !replace_field.nil?
                                              
                                              if replace_field.to_s == "headline"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Headline Success. "
                                              end
                                              
                                              if replace_field.to_s == "desc_1"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Description Success. "
                                              end
                                              
                                              if replace_field.to_s == "display_url"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Display Url Success. "
                                              end
                                              
                                              if replace_field.to_s == "final_url"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Final Url Success. "
                                              end
                                              
                                              if replace_field.to_s == "mobile_display_url"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Mobile Display Url Success. "
                                              end
                                              
                                              if replace_field.to_s == "mobile_final_url"
                                                  update_msg_array << "Update "+real_id[1].to_s+ " Display Final Success. "
                                              end
                                              
                                              
                                              
                                              @ad = @db[db_name].find('ad_id' => @ad_id.to_i).update_one('$set'=> { 
                                                                                                                      'title' => @title.to_s,
                                                                                                                      'description' => @description.to_s,
                                                                                                                      'visit_url' => @final_url.to_s,
                                                                                                                      'show_url' => @display_url.to_s,
                                                                                                                      'mobile_show_url' => @m_display_url.to_s,
                                                                                                                      'mobile_visit_url' => @m_final_url.to_s
                                                                                                                    })
                                              @db.close                                                                     
                                          end
                                                                  
                                          if !status.nil?
                                              @ad = @db[db_name].find('ad_id' => @ad_id.to_i).update_one('$set'=> { 'status' => db_status.to_s })
                                              @db.close
                                              update_msg_array << "Update '"+real_id[1].to_s+ "' Status Success. "
                                          end
                                      end
                                      
                                      # @logger.info @affectedRecords
                                      # @logger.info @update_res
                                      
                                  end
                             end
                         
                         end
                    end
              end
          end
          
          data = {:message => "Complete. <br /><br />"+update_msg_array.join("<br />")+"<br /><br />Please Refresh to see the latest update.<br />P.S Your Channel takes up to 24 hours to update the changes.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end      
      return render :json => data, :status => :ok
      
  end
  
  
  
  
  
  def threesixtyupdatekeyword
      
      
      id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
    
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
      
      
      cpc_action_type = params[:action_type]
      cpc_value = params[:value]
      classifier = params[:classifier]
      
      status = params[:status]
      
      if status.to_s == "inactive"
          status = "pause"
          db_status = "暂停"
      end
      if status.to_s == "active"
          status = "enable"
          db_status = "启用"
      end
      
      if id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "threesixty"
        data = {:message => "Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      
      update_msg_array = []
      
      begin
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                    
                    @username = network_d["username"]
                    @password = network_d["password"]
                    @apitoken = network_d["api_token"]
                    @apisecret = network_d["api_secret"]
                                         
                    login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                    @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                    
                    if @refresh_token.nil?
                        data = {:message => "API Info not correct", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                    @remain_quote = @response.headers["quotaremain"].to_i
                    
                    if @remain_quote.to_i <= 500
                        data = {:message => "<p>360 Account " + network_d["name"] + " doesn't have enough quota.</p>", :status => "false"}
                        return render :json => data, :status => :ok
                    end
                    
                    @tracking_type = network_d["tracking_type"].to_s
                    @ad_redirect = network_d["ad_redirect"].to_s
                    @keyword_redirect = network_d["keyword_redirect"].to_s
                    @company_id = network_d["company_id"].to_s
                    @cookie_length = network_d["cookie_length"].to_s
                    
                    # @logger.info id_array
                    
                    id_array.each do |id_array_d|
                        
                        requesttypearray = []
                        real_id = id_array_d.split("|")
                        
                        if @remain_quote.to_i <= 500
                            update_msg_array << "Update keyword " + real_id[2].to_s + " failed. Not enough quota."
                        else
                            db_name = "keyword_360_"+network_id.to_s
                            @keyword = @db[db_name].find('keyword_id' => real_id[0].to_i)
                            @db.close
                            
                            if @keyword.count.to_i > 0
                                  @keyword.each do |keyword_d|
                                      @final_url = keyword_d["visit_url"]
                                      @m_final_url = keyword_d["mobile_visit_url"]
                                      @price = keyword_d["price"]
                                      
                                      if !replace_field.nil?
                                          if replace_field.to_s == "final_url"
                                            
                                             @logger.info @final_url
                                            
                                             if @final_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)  
                                             end
                                             
                                             @final_url = @final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                             
                                             
                                             if !@final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                  @temp_final_url = @final_url
                                                  
                                                  @final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                                  @final_url = @final_url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id="+real_id[0].to_s
                                                  @final_url = @final_url + "&cookie="+@cookie_length.to_s
                                                  @final_url = @final_url + "&device=pc"
                                                  @final_url = @final_url + "&tv=v1&durl="+CGI.escape(@temp_final_url.to_s)
                                              end
                                              
                                             request_str = '{"id":'+real_id[0]+',"url":"'+@final_url+'"}'
                                          end
                                          
                                          if replace_field.to_s == "mobile_final_url"
                                              if @m_final_url.include?(".adeqo.")
                                                  tmp_replace_field_find = CGI.escape(replace_field_find)
                                                  tmp_replace_field_replace = CGI.escape(replace_field_replace)  
                                              end
                                              @m_final_url = @m_final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                              
                                              if !@m_final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                  @temp_m_final_url = @m_final_url
                                                  
                                                  @m_final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                                  @m_final_url = @m_final_url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id="+real_id[0].to_s
                                                  @m_final_url = @m_final_url + "&cookie="+@cookie_length.to_s
                                                  @m_final_url = @m_final_url + "&device=mobile"
                                                  @m_final_url = @m_final_url + "&tv=v1&durl="+CGI.escape(@temp_m_final_url.to_s)
                                              end
                                              
                                              request_str = '{"id":'+real_id[0]+',"mobileUrl":"'+@m_final_url+'"}'
                                          end
                                      end
                                      
                                      if !status.nil?
                                          request_str = '{"id":'+real_id[0]+',"status":"'+status+'"}'
                                      end
                                      
                                      if !cpc_action_type.nil?
                                                  
                                          if cpc_action_type.to_s == "set"
                                              @new_price = cpc_value.to_f
                                              @new_price = @new_price.round(2)
                                              request_str = '{"id":'+real_id[0]+',"price":"'+@new_price.to_f.to_s+'"}'
                                          end
                                          
                                          if cpc_action_type.to_s == "increase"
                                              if classifier.to_s == "RMB"
                                                  @new_price = @price.to_f + cpc_value.to_f
                                                  @new_price = @new_price.round(2)
                                                  request_str = '{"id":'+real_id[0]+',"price":"'+@new_price.to_f.to_s+'"}'
                                              end
                                              
                                              if classifier.to_s == "%"
                                                  @new_price = @price.to_f + (@price.to_f*cpc_value.to_f)/100
                                                  @new_price = @new_price.round(2)
                                                  request_str = '{"id":'+real_id[0]+',"price":"'+@new_price.to_f.to_s+'"}'
                                              end
                                                
                                          end
                                          
                                          if cpc_action_type.to_s == "decrease"
                                              if classifier.to_s == "RMB"
                                                  @new_price = @price.to_f - cpc_value.to_f
                                                  @new_price = @new_price.round(2)
                                                  request_str = '{"id":'+real_id[0]+',"price":"'+@new_price.to_f.to_s+'"}'
                                              end
                                              
                                              if classifier.to_s == "%"
                                                  @new_price = @price.to_f - (@price.to_f*cpc_value.to_f)/100
                                                  @new_price = @new_price.round(2)
                                                  request_str = '{"id":'+real_id[0]+',"price":"'+@new_price.to_f.to_s+'"}'
                                              end
                                          end
                                          
                                      end
                                      
                                      @logger.info request_str
                                      @logger.info ""
                                      requesttypearray << request_str
                                      request = '['+requesttypearray.join(",")+']'
                                      
                                      body = { 
                                          'keywords' => request
                                      }
                                      @logger.info request
                                      @logger.info ""
                                      
                                      @update_res = threesixty_api( network_d["api_token"].to_s, @refresh_token, "keyword", "update", body)
                                      @affectedRecords = @update_res["keyword_update_response"]["affectedRecords"]
                                      @remain_quote = @response.headers["quotaremain"].to_i
                                      
                                      if !@update_res["keyword_update_response"]["failures"].nil?
                                          update_msg_array << "Update '"+real_id[1].to_s+ "' failed. " + @update_res["keyword_update_response"]["failures"]["item"]["message"]
                                      else
                                          if !replace_field.nil?
                                              if replace_field.to_s == "final_url"
                                                  update_msg_array << "Update '"+real_id[2].to_s+ "' Final Success "
                                              end
                                              
                                              if replace_field.to_s == "mobile_final_url"
                                                  update_msg_array << "Update '"+real_id[2].to_s+ "' Mobile Final Success "
                                              end
                                            
                                              @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'visit_url' => @final_url.to_s, 'mobile_visit_url' => @m_final_url.to_s  })
                                              @db.close
                                          end
                                          
                                          if !status.nil?
                                              @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'status' => db_status.to_s })
                                              @db.close
                                              update_msg_array << "Update '"+real_id[2].to_s+ "' Status Success "
                                          end
                                          
                                          if !cpc_action_type.nil?
                                              update_msg_array << "Set Keyword '"+real_id[2].to_s+ "' Price to "+ @new_price.to_s   
                                              @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'price' => @new_price.to_f })
                                              @db.close
                                          end
                                      end
                                      
                                      # @logger.info @affectedRecords
                                      @logger.info @update_res
                                      @logger.info ""
                                  end
                             end
                         end
                    end
                    
                    
              end
          end
          
          data = {:message => "Complete. <br /><br />" + update_msg_array.join("<br />")+"<br /><br />Please Refresh to see the latest update.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  def sogouupdateadgroup
      id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
      
      pause = nil
      status = params[:status]
      if status.to_s == "inactive"
          pause = "true"
          db_status = 22
      end
      if status.to_s == "active"
          pause = "false"
          db_status = 21
      end
      
      cpc_action_type = params[:action_type]
      cpc_value = params[:value]
      classifier = params[:classifier]
      
      
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
      
      
      if id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "sogou"
        data = {:message => "Network Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      update_msg_array = []
      
      begin 
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                  sogou_result = @sogou_api.call(:get_account_info)
                  
                  if sogou_result.header[:res_header][:desc].to_s != "success"
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + "" + sogou_result.header[:res_header][:failures][:message].to_s, :status => "false"}
                      return render :json => data, :status => :ok
                  end
                  
                  
                  @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                  if @remain_quote.to_i <= 500
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + " doesn't have enough quota.</p>", :status => "false"}
                      return render :json => data, :status => :ok
                  end
    
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcGrpService")
                  
                  id_array.each do |id_array_d|
      
                      real_id = id_array_d.split('|')
                      
                      if @remain_quote.to_i <= 500
                          update_msg_array << "Update Adgroup " + real_id[1].to_s + " failed. Not enough quota."
                      else  
                      
                          # ******************************************************set db name here
                          db_name = "adgroup_sogou_"+network_id.to_s
                          @adgroup = @db[db_name].find('cpc_grp_id' => real_id[0].to_i)
                          @db.close
                          # ******************************************************
                          
                          if @adgroup.count.to_i > 0
                                @adgroup.each do |adgroup_d|
                                    @price = adgroup_d["max_price"]
                                    @name = adgroup_d["name"]
                                    
                                    requesttypearray = []
                                    requesttype = {}
                                    requesttype[:cpcGrpId]    =     real_id[0].to_i
                                    requesttype[:cpcPlanId]    =     0
                                    
                                    if !replace_field.nil?
                                        if replace_field.to_s == "adgroup_name"
                                          @name = @name.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                          requesttype[:cpcGrpName]    =     @name
                                        end
                                    end
                                    
                                    if !pause.nil?
                                        requesttype[:pause]    =     pause
                                    end
                                    
                                    if !cpc_action_type.nil?
                                        if cpc_action_type.to_s == "set"
                                            @new_price = cpc_value.to_f
                                            @new_price = @new_price.round(2)
                                            requesttype[:maxPrice]         =     @new_price.to_f  
                                        end
                                        
                                        if cpc_action_type.to_s == "increase"
                                            if classifier.to_s == "RMB"
                                                @new_price = @price.to_f + cpc_value.to_f
                                                @new_price = @new_price.round(2)
                                                requesttype[:maxPrice]         =     @new_price.to_f
                                            end
                                            
                                            if classifier.to_s == "%"
                                                @new_price = @price.to_f + (@price.to_f*cpc_value.to_f)/100
                                                @new_price = @new_price.round(2)
                                                requesttype[:maxPrice]         =     @new_price
                                            end
                                        end
                                        
                                        if cpc_action_type.to_s == "decrease"
                                            if classifier.to_s == "RMB"
                                                @new_price = @price.to_f - cpc_value.to_f
                                                @new_price = @new_price.round(2)
                                                requesttype[:maxPrice]         =     @new_price.to_f
                                            end
                                            
                                            if classifier.to_s == "%"
                                                @new_price = @price.to_f - (@price.to_f*cpc_value.to_f)/100
                                                @new_price = @new_price.round(2)
                                                requesttype[:maxPrice]         =     @new_price
                                            end
                                        end
                                    end
                                    requesttypearray << requesttype
                                    
                                    # # @logger.info requesttypearray
                                    @update_status = @sogou_api.call(:update_cpc_grp, message: { cpcGrpTypes: requesttypearray })
                                    
                                    
                                    @header = @update_status.header.to_hash
                                    @msg = @header[:res_header][:desc]
                                    @remain_quote = @header[:res_header][:rquota]
                                    
                                    # @logger.info @header 
                                    # @return_num =  @header[:res_header][:oprs]
                                     
                                    # @update_status_body = @update_status.body.to_hash
                                    # # @logger.info @update_status_body
                                    
                                    if @msg.to_s.downcase == "success"
                                      
                                        if !replace_field.nil?
                                            if replace_field.to_s == "adgroup_name"
                                                update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "' name to "+ @name.to_s + " Success."
                                                @db[db_name].find('cpc_grp_id' => real_id[0].to_i).update_one('$set'=> { 'name' => @name.to_s })
                                                @db.close
                                            end
                                        end
                                        
                                        if !pause.nil?
                                            update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "' to "+ status.to_s + " Success."
                                            @db[db_name].find('cpc_grp_id' => real_id[0].to_i).update_one('$set'=> { 'status' => db_status.to_i, 'pause' => pause.to_s })
                                            @db.close
                                        end
                                        
                                        
                                        if !cpc_action_type.nil?
                                            update_msg_array << "Set Adgroup '"+real_id[1].to_s+ "' Price to "+ @new_price.to_s + " Success."
                                            @db[db_name].find('cpc_grp_id' => real_id[0].to_i).update_one('$set'=> { 'max_price' => @new_price.to_f })
                                            @db.close 
                                        end
                                        
                                    else
                                        update_msg_array << "Update Adgroup " +real_id[1].to_s + " failed. " + @header[:res_header][:failures][:message].to_s
                                    end
                                    
                                end
                          end
                      end
                  end
              end
          end
          
          data = {:message => "Complete. <br /><br />"+update_msg_array.join("<br />")+"<br /><br />Please refresh to see the latest changes.", :status => "true"}
      
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end
      
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  def sogouupdatead
       
      ad_id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
      
      campaign_id = params[:campaign_id]
      
      pause = nil
      status = params[:status]
      if status.to_s == "inactive"
          pause = "true"
          db_status = 42
      end
      if status.to_s == "active"
          pause = "false"
          db_status = 44
      end
      
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
        
      if ad_id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "sogou"
        data = {:message => "Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      
      update_msg_array = []
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      
      begin
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                  
                  @tracking_type = network_d["tracking_type"].to_s
                  @ad_redirect = network_d["ad_redirect"].to_s
                  @keyword_redirect = network_d["keyword_redirect"].to_s
                  @company_id = network_d["company_id"].to_s
                  @cookie_length = network_d["cookie_length"].to_s
                                
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                  sogou_result = @sogou_api.call(:get_account_info)
                  
                  if sogou_result.header[:res_header][:desc].to_s != "success"
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + "" + sogou_result.header[:res_header][:failures][:message].to_s, :status => "false"}
                      return render :json => data, :status => :ok
                  end
                  
                  @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                  if @remain_quote.to_i <= 500
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + " doesn't have enough quota.</p>", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                  
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcIdeaService")
                
                  ad_id_array.each do |ad_id_array_d|
                      
                      real_id = ad_id_array_d.split("|")
                      
                      replace_field_find = params[:field_find]
                      replace_field_replace = params[:field_replace]
      
                      if @remain_quote.to_i <= 500
                          update_msg_array << "Update Ad " + real_id[1].to_s + " failed. Not enough quota."
                      else  
                          db_name = "ad_sogou_"+network_id.to_s
                          @ad = @db[db_name].find('cpc_idea_id' => real_id[0].to_i)
                          @db.close
                          
                          if @ad.count.to_i > 0
                                @ad.each do |ad_d|
                                    @title = ad_d["title"]
                                    @description_1 = ad_d["description_1"]
                                    @description_2 = ad_d["description_2"]
                                    @display_url = ad_d["show_url"]
                                    @final_url = ad_d["visit_url"]
                                    @m_display_url = ad_d["mobile_show_url"]
                                    @m_final_url = ad_d["mobile_visit_url"]
                                    
                                    requesttypearray = [] 
                                    requesttype = {}
                                    requesttype[:cpcIdeaId]    =     real_id[0].to_i
                                    requesttype[:cpcGrpId]    =     0
                                    
                                    if !pause.nil?
                                        requesttype[:pause]    =     pause
                                    end
                                    
                                    if !replace_field.nil?
                                        if replace_field.to_s == "headline"
                                            @title = @title.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                            requesttype[:title] = @title
                                        end
                                        
                                        if replace_field.to_s == "desc_1"
                                            @description_1 = @description_1.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                            requesttype[:description1] = @description_1
                                        end
                                        
                                        if replace_field.to_s == "desc_2"
                                            @description_2 = @description_2.gsub(replace_field_find.to_s, replace_field_replace.to_s)
                                            requesttype[:description2] = @description_2
                                        end
                                        
                                        if replace_field.to_s == "display_url"
                                            if @display_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                            end
                                            
                                            @display_url = @display_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                            requesttype[:showUrl]         =     @display_url  
                                        end
                                        
                                        if replace_field.to_s == "final_url"
                                          
                                            if @final_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                            end
                                            
                                            @final_url = @final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                            
                                            if !@final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                @temp_final_url = @final_url
                                                @final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_i.to_s
                                                @final_url = @final_url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+real_id[0].to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                                @final_url = @final_url + "&cookie="+@cookie_length.to_s
                                                @final_url = @final_url + "&device=pc"
                                                @final_url = @final_url + "&tv=v1&durl="+CGI.escape(@temp_final_url.to_s)
                                            end
                                            
                                            requesttype[:visitUrl]    =     @final_url
                                        end
                                        
                                        if replace_field.to_s == "mobile_display_url"
                                            if @m_display_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                            end
                                            
                                            @m_display_url = @m_display_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                            requesttype[:mobileShowUrl]   =  @m_display_url  
                                        end
                                        
                                        if replace_field.to_s == "mobile_final_url"
                                            if @m_final_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                            end
                                            
                                            @m_final_url = @m_final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                            
                                            if !@m_final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                @temp_m_final_url = @m_final_url
                                                @m_final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_i.to_s
                                                @m_final_url = @m_final_url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+real_id[0].to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                                @m_final_url = @m_final_url + "&cookie="+@cookie_length.to_s
                                                @m_final_url = @m_final_url + "&device=mobile"
                                                @m_final_url = @m_final_url + "&tv=v1&durl="+CGI.escape(@temp_m_final_url.to_s)
                                            end
                                            
                                            requesttype[:mobileVisitUrl] =    @m_final_url
                                        end
                                    end
                                    
                                    
                                    requesttypearray << requesttype
                                    
                                    # @logger.info requesttypearray
                                    @update_status = @sogou_api.call(:update_cpc_idea, message: { cpcIdeaTypes: requesttypearray })
                                                             
                                    @header = @update_status.header.to_hash
                                    @msg = @header[:res_header][:desc]
                                    @remain_quote = @header[:res_header][:rquota]
                                                                                                         
                                    # @logger.info @header 
                                    
                                    # @update_status_body = @update_status.body.to_hash
                                    # # @logger.info @update_status_body
                                    if @msg.to_s.downcase == "success"
                                        if !pause.nil?
                                            update_msg_array << "Set Ad '"+real_id[1].to_s+ "' to "+ status.to_s + " Success."
                                            @db[db_name].find('cpc_idea_id' => real_id[0].to_i).update_one('$set'=> { 'pause' => pause.to_s, 'status' => db_status.to_i })
                                            @db.close
                                        end
                                        
                                        
                                        if !replace_field.nil?
                                            if replace_field.to_s == "headline"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Headline to "+ @title.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "desc_1"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Description 1 to "+ @description_1.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "desc_2"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Description 2 to "+ @description_2.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "display_url"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Display URL to "+ @display_url.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "final_url"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Landing URL to "+ @final_url.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "mobile_display_url"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Mobile Display URL to "+ @m_display_url.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "mobile_final_url"
                                                update_msg_array << "Set Ad '"+real_id[1].to_s+ "' Mobile Landing URL to "+ @m_final_url.to_s + " Success."
                                            end
                                            
                                            @db[db_name].find('cpc_idea_id' => real_id[0].to_i).update_one('$set'=> {   
                                                                                                                        'title' => @title.to_s,
                                                                                                                        'description_1' => @description_1.to_s,
                                                                                                                        'description_2' => @description_2.to_s,
                                                                                                                        'visit_url' => @final_url.to_s,
                                                                                                                        'show_url' => @display_url.to_s,
                                                                                                                        'mobile_visit_url' => @m_final_url.to_s,
                                                                                                                        'mobile_show_url' => @m_display_url.to_s  
                                                                                                                      })
                                            @db.close
                                        end
                                        
                                        
                                    else
                                        update_msg_array << "Update Ad " +real_id[1].to_s + " failed. " + @header[:res_header][:failures][:message].to_s
                                    end
                                end
                          end 
                      end                                                             
                  end   
                    
              end
          end
          
          data = {:message => "Complete. <br /><br />"+update_msg_array.join("<br />").to_s+"<br /><br />Please refresh to see the latest changes.<br />P.S Your Channel may take up to 24 hours to process your request.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end
      
      return render :json => data, :status => :ok
      
  end
  
  
  
  def sogouupdatekeyword
    
      id_array = params[:item_id]
      type = params[:campaign_type]
      network_id = params[:network_id]
      
      campaign_id = params[:campaign_id]
      
      pause = nil
      status = params[:status]
      if status.to_s == "inactive"
          pause = "true"
          db_status = 32
      end
      if status.to_s == "active"
          pause = "false"
          db_status = 35
      end
      
      cpc_action_type = params[:action_type]
      cpc_value = params[:value]
      classifier = params[:classifier]
      
      
      replace_field = params[:field_name]
      replace_field_find = params[:field_find]
      replace_field_replace = params[:field_replace]
      
      if id_array.nil? || type.nil? || network_id.nil?
        data = {:message => "Post Data Missing", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      if type.to_s != "sogou"
        data = {:message => "Type Error", :status => "false"}
        return render :json => data, :status => :ok
      end
      
      @network = @db[:network].find(id: network_id.to_i)
      @db.close
      update_msg_array = []
      
      begin 
          if @network.count.to_i > 0
          
              @network.each do |network_d|
                  
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                  sogou_result = @sogou_api.call(:get_account_info)
                  
                  if sogou_result.header[:res_header][:desc].to_s != "success"
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + "" + sogou_result.header[:res_header][:failures][:message].to_s, :status => "false"}
                      return render :json => data, :status => :ok
                  end
                  
                  
                  @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                  if @remain_quote.to_i <= 500
                      data = {:message => "<p>Sogou Account " + network_d["name"].to_s + " doesn't have enough quota.</p>", :status => "false"}
                      return render :json => data, :status => :ok
                  end
                  
                  sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcService")
                  
                  @tracking_type = network_d["tracking_type"].to_s
                  @ad_redirect = network_d["ad_redirect"].to_s
                  @keyword_redirect = network_d["keyword_redirect"].to_s
                  @company_id = network_d["company_id"].to_s
                  @cookie_length = network_d["cookie_length"].to_s
                    
                  id_array.each do |id_array_d|
      
                      real_id = id_array_d.split("|")
                      
                      if @remain_quote.to_i <= 500
                          update_msg_array << "Update Keyword " + real_id[2].to_s + " failed. Not enough quota."
                      else
                        
                          db_name = "keyword_sogou_"+network_id.to_s
                          @keyword = @db[db_name].find('keyword_id' => real_id[0].to_i)
                          @db.close
                          
                          if @keyword.count.to_i > 0
                                @keyword.each do |keyword_d|
                                    @final_url = keyword_d["visit_url"]
                                    @m_final_url = keyword_d["mobile_visit_url"]
                                    @price = keyword_d["price"]

        
                                    requesttypearray = [] 
                                    requesttype = {}
                                    requesttype[:cpcId]    =     real_id[0].to_i
                                    requesttype[:cpc]    =     0
                                    requesttype[:cpcGrpId]    =     0
                                    
                                    if !replace_field.nil?
                                        if replace_field.to_s == "final_url"
                                           if @final_url.include?(".adeqo.")
                                               tmp_replace_field_find = CGI.escape(replace_field_find)
                                               tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                           end
                                           @final_url = @final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                           
                                           if !@final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                @temp_final_url = @final_url
                                                @final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_i.to_s
                                                @final_url = @final_url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+keyword_d["cpc_grp_id"].to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                                @final_url = @final_url + "&cookie="+@cookie_length.to_s
                                                @final_url = @final_url + "&device=pc"
                                                @final_url = @final_url + "&tv=v1&durl="+CGI.escape(@temp_final_url.to_s)
                                            end
                                            
                                           requesttype[:visitUrl]    =     @final_url
                                        end
                                        
                                        if replace_field.to_s == "mobile_final_url"
                                            if @m_final_url.include?(".adeqo.")
                                                tmp_replace_field_find = CGI.escape(replace_field_find)
                                                tmp_replace_field_replace = CGI.escape(replace_field_replace)
                                            end
                                            @m_final_url = @m_final_url.gsub(tmp_replace_field_find.to_s, tmp_replace_field_replace.to_s)
                                            
                                            if !@m_final_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" && @ad_redirect.to_s.downcase == "yes"
                                                @temp_m_final_url = @m_final_url
                                                @m_final_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_i.to_s
                                                @m_final_url = @m_final_url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+keyword_d["cpc_grp_id"].to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                                @m_final_url = @m_final_url + "&cookie="+@cookie_length.to_s
                                                @m_final_url = @m_final_url + "&device=mobile"
                                                @m_final_url = @m_final_url + "&tv=v1&durl="+CGI.escape(@temp_m_final_url.to_s)
                                            end
                                            
                                            requesttype[:mobileVisitUrl] =  @m_final_url
                                        end
                                    end
                                    
                                    if !pause.nil?
                                        requesttype[:pause]    =     pause
                                    end
                                    
                                    if !cpc_action_type.nil?
                                        if cpc_action_type.to_s == "set"
                                            @new_price = cpc_value.to_f
                                            @new_price = @new_price.round(2)
                                            requesttype[:price]         =     @new_price  
                                        end
                                        
                                        if cpc_action_type.to_s == "increase"
                                            if classifier.to_s == "RMB"
                                                @new_price = @price.to_f + cpc_value.to_f
                                                @new_price = @new_price.round(2)
                                                requesttype[:price]         =     @new_price.to_f
                                            end
                                            
                                            if classifier.to_s == "%"
                                                @new_price = @price.to_f + (@price.to_f*cpc_value.to_f)/100
                                                @new_price = @new_price.round(2)
                                                requesttype[:price]         =     @new_price
                                            end
                                              
                                        end
                                        
                                        if cpc_action_type.to_s == "decrease"
                                            if classifier.to_s == "RMB"
                                                @new_price = @price.to_f - cpc_value.to_f
                                                @new_price = @new_price.round(2)
                                                requesttype[:price]         =     @new_price
                                            end
                                            
                                            if classifier.to_s == "%"
                                                @new_price = @price.to_f - (@price.to_f*cpc_value.to_f)/100
                                                @new_price = @new_price.round(2)
                                                requesttype[:price]         =     @new_price
                                            end
                                        end
                                    end
                                    
                                    requesttypearray << requesttype
                                    
                                    # @logger.info requesttypearray
                                    @update_status = @sogou_api.call(:update_cpc, message: { cpcTypes: requesttypearray })
                                                                                                         
                                    @header = @update_status.header.to_hash
                                    @msg = @header[:res_header][:desc]
                                    @remain_quote = @header[:res_header][:rquota]
                                                                                                         
                                    # @logger.info @header 
                                    @update_status_body = @update_status.body.to_hash
                                    # # @logger.info @update_status_body
                                    
                                    if @msg.to_s.downcase == "success"
                                        if !pause.nil?
                                            update_msg_array << "Set Keyword '"+real_id[2].to_s+ "' to "+ status.to_s + " Success."
                                            @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'pause' => pause.to_s, 'status' => @update_status_body[:update_cpc_response][:cpc_types][:status].to_i })
                                            @db.close
                                        end
                                        
                                        if !cpc_action_type.nil?
                                            update_msg_array << "Set Keyword '"+real_id[2].to_s+ "' Price to "+ @new_price.to_s + " Success."
                                            @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'price' => @new_price.to_f })
                                            @db.close
                                        end
                                        
                                        if !replace_field.nil?
                                            if replace_field.to_s == "final_url"
                                                update_msg_array << "Set Keyword '"+real_id[2].to_s+ "' Landing Url to "+ @final_url.to_s + " Success."
                                            end
                                            
                                            if replace_field.to_s == "mobile_final_url"
                                                update_msg_array << "Set Keyword '"+real_id[2].to_s+ "' Landing Url to "+ @m_final_url.to_s + " Success."
                                            end
                                            
                                            @db[db_name].find('keyword_id' => real_id[0].to_i).update_one('$set'=> { 'visit_url' => @final_url.to_s,
                                                                                                                        'mobile_visit_url' => @m_final_url.to_s
                                                                                                                  })
                                            @db.close
                                        end
                                        
                                    else
                                        update_msg_array << "Update Keyword " +real_id[2].to_s + " failed. " + @header[:res_header][:failures][:message].to_s
                                    end
                                end
                          end
                      end
                  end
              end
              
          end
          
          data = {:message => "Complete. <br /><br />" + update_msg_array.join("<br />")+"<br /><br />Please refresh to see the latest changes.", :status => "true"}
      rescue Exception
          data = {:message => "Ad Channel is busy, please try again later.", :status => "true"}
      end
      
      return render :json => data, :status => :ok
      
  end
  
  
  
  
  
  
  # _____________________________________________________________________________________________________________
  
  def addnetworkuser      
      if @user_role.to_s == "read"
        data = {:message => "You cant add anything", :status => "false"}
        return render :json => data, :status => :ok
      end
    
    
      @network_id_array = params[:network_id_array]
      @user_id =  params[:user_id]
      
      if @user_id.nil? || @network_id_array.nil?
          data = {:message => "Error input", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      
      @network_id_array.each do |network|
          @db[:network_user].insert_one({ network_id: network.to_i,
                                          user: @user_id.to_i })
          @db.close
      end
      
      
      data = {:message => "Selected accounts have been added to the portfolio.", :status => "false"}
      return render :json => data, :status => :ok
      
  end
  
  def removenetworkuser
      if @user_role.to_s == "read"
        data = {:message => "You cant delete anything", :status => "false"}
        return render :json => data, :role=> @user_role, :status => :ok
      end
      
      @network_id_array = params[:network_id_array]
      @user_id =  params[:user_id]
      
      if @user_id.nil? || @network_id_array.nil?
          data = {:message => "Error input", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      
      @network_id_array.each do |network|
          @db[:network_user].find('network_id' => network.to_i, 'user' => @user_id.to_i).delete_one
          @db.close
      end
      
      
      data = {:message => "Done", :status => "true"}
      return render :json => data, :status => :ok
  end
  
  def editnetwork
    
    if @user_role == "read"
      data = {:message => "You cant edit anything", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @network_id_str =  params[:id]
    
    @budget =  params[:budget]
    @network_type =  params[:network_type]
    @network_name =  params[:network_name]
    @currency =  params[:currency]
    @ad_redirect =  params[:ad_redirect]
    @keyword_redirect =  params[:keyword_redirect]
    @username =  params[:username]
    @password =  params[:password]
    @apitoken =  params[:apitoken]
    @tracking_type =  params[:tracking_type]
    @cookie_length =  params[:cookie_length]
    @apisecret =  params[:apisecret]
    
    @remove_array = @network_id_str.split("_")
    @type = @remove_array[0]
    @id = @remove_array[1]
    
    
    if(@network_name.nil? || @username.nil? || @password.nil? || @apitoken.nil?)
      data = {:message => "Missing some Data", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @network = @db[:network].find('type' => @network_type.to_s, 'id' => @id.to_i)
    @db.close
    
    if @network.count.to_i != 1
        data = {:message => "No Network found", :status => "false"}
        return render :json => data, :status => :ok
    else
        
        if @network_type.to_s == "sogou"
              sogou_api(@username,@password,@apitoken,"AccountService")
              @sogou_result = @sogou_api.call(:get_account_info)
              
              @sogou_body = @sogou_result.body.to_hash
              @sogou_body = @sogou_body[:get_account_info_response][:account_info_type]
              
              @header = @sogou_result.header.to_hash
              @return_num =  @header[:res_header][:oprs]
              @quota =  @header[:res_header][:rquota]
                
              # # @logger.info @header  
                
              if @header[:res_header][:desc].to_s == "success"
                @accountid = @sogou_body[:accountid]
                @balance = @sogou_body[:balance]
                # @budget = @sogou_body[:budget]
                @domains = @sogou_body[:domains]
                @regions = @sogou_body[:regions]
                @total_cost = @sogou_body[:total_cost]
                @total_pay = @sogou_body[:total_pay]
                
              else
                data = {:message => "API Info not correct", :status => "false"}
                return render :json => data, :status => :ok
              end
        elsif @network_type.to_s == "360"
          
              login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
              @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
              
              # @logger.info login_info
              
              if @refresh_token.nil?
                  data = {:message => "API Info not correct", :status => "false"}
                  return render :json => data, :status => :ok
              end
              
              @db[:network].find(id: @id.to_i).update_one('$set'=>  {     
                                                                       api_secret: @apisecret.to_s                                                                     
                                                                    })
              @db.close
          
        else
              data = {:message => "Only sogou/360 for now", :status => "false"}
              return render :json => data, :status => :ok
        end
        
        @db[:network].find(id: @id.to_i).update_one('$set'=>      {     
                                                                       name:@network_name.to_s,
                                                                       currency: @currency.to_s,
                                                                       password: @password.to_s,
                                                                       budget: @budget.to_i, 
                                                                       api_token: @apitoken.to_s, 
                                                                       tracking_type: @tracking_type.to_s, 
                                                                       ad_redirect: @ad_redirect.to_s,
                                                                       keyword_redirect: @keyword_redirect.to_s,
                                                                       cookie_length: @cookie_length.to_s                                                                     
                                                                    })
        
        
        @db.close
        data = {:message => "Done", :status => "true"}
        return render :json => data, :status => :ok
    end
  end
  
  
  def getnetwork
    
    if @user_role == "read"
      data = {:message => "You cant edit anything", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @id_str =  params[:id_str]
    
    @remove_array = @id_str.split("_")
    @type = @remove_array[0]
    @id = @remove_array[1]
    
    @network = @db[:network].find('type' => @type.to_s, 'id' => @id.to_i)
    @db.close
    
    if @network.count.to_i == 0 
        data = {:message => "No Network found", :status => "false"}
        return render :json => data, :status => :ok
    else
        data = {:message => "Done", :status => "true", :network => @network}
        return render :json => data, :status => :ok
    end
    
  end
  
  
  
  
  
  def removenetwork
    if @user_role == "read"
      data = {:message => "You cant delete anything", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    
    # @id =  params[:remove_id]
    @id_array =  params[:remove_id_array]
    @done_array = []
    @fail_array = []
    
    if !@id_array.nil?
        @id_array.each do |id|
            @remove_array = id.split("_")
            @type = @remove_array[0]
            @id = @remove_array[1]
            
            @db[:network].find('id' => @id.to_i).delete_one
            @db.close
            @db[:all_campaign].find('network_id' => @id.to_i).delete_many
            @db.close
                
            if @type == "sogou"
                
                db_name = "adgroup_sogou_"+@id.to_s
                @db[db_name].drop()
                
                db_name = "ad_sogou_"+@id.to_s
                @db[db_name].drop()
                
                db_name = "keyword_sogou_"+@id.to_s
                @db[db_name].drop()

                
                @db3[:sogou_report_account].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:sogou_report_campaign].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:sogou_report_adgroup].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:sogou_report_ad].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:sogou_report_keyword].find('network_id' => @id.to_i).delete_many
                @db3.close
                
                @db3[:sogou_avg_position_desktop].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:sogou_avg_position_desktop].find('network_id' => @id.to_i).delete_many
                @db3.close
                                
                @done_array << @id
                
            elsif @type == "360"
                
                db_name = "adgroup_360_"+@id.to_s
                @db[db_name].drop()
                
                db_name = "ad_360_"+@id.to_s
                @db[db_name].drop()
                
                db_name = "keyword_360_"+@id.to_s
                @db[db_name].drop()
                
                
                @db3[:report_account_360].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:report_campaign_360].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:report_adgroup_360].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:report_ad_360].find('network_id' => @id.to_i).delete_many
                @db3.close
                @db3[:report_keyword_360].find('network_id' => @id.to_i).delete_many
                @db3.close
                
                
                @done_array << @id
            else
                @fail_array << @id
            end
            
            @db[:network_user].find('network_id' => @id.to_i).delete_many
            @db.close
        end  
    end
    
    
    if @fail_array.count != 0 
        data = {:message => "These not deleted.", :status => "false"}
        return render :json => data, :status => :ok
    else
        data = {:message => "Removed all data", :status => "true"}
        return render :json => data, :status => :ok
    end
  end
  
  
  
  def createnetwork
    
    if @user_role == "read"
      data = {:message => "You cant add anything", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @network_type =  params[:network_type]
    @network_name =  params[:network_name]
    @currency =  params[:currency]
    @ad_redirect =  params[:ad_redirect]
    @keyword_redirect =  params[:keyword_redirect]
    @username =  params[:username]
    @password =  params[:password]
    @apitoken =  params[:apitoken]
    @budget =  params[:budget]
    @tracking_type =  params[:tracking_type]
    @cookie_length =  params[:cookie_length]
    
    
    last_network_id = get_last_id("network")
    
    if(@network_name.nil? || @username.nil? || @password.nil? || @apitoken.nil?)
      data = {:message => "Missing some Data", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @current_network = @db[:network].find('type' => @network_type.to_s, 'username' => @username.to_s)
    @db.close
    
    if @current_network.count.to_i > 0
      data = {:message => "This sogou account already added in adeqo.", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    
    if @network_type.to_s == "sogou"
      sogou_api(@username,@password,@apitoken,"AccountService")
      @sogou_result = @sogou_api.call(:get_account_info)
      
      @sogou_body = @sogou_result.body.to_hash
      @sogou_body = @sogou_body[:get_account_info_response][:account_info_type]
      
      @header = @sogou_result.header.to_hash
      @return_num =  @header[:res_header][:oprs]
      @quota =  @header[:res_header][:rquota]
        
      if @header[:res_header][:desc].to_s == "success"
        @accountid = @sogou_body[:accountid]
        @balance = @sogou_body[:balance]
        # @budget = @sogou_body[:budget]
        @domains = @sogou_body[:domains]
        @regions = @sogou_body[:regions]
        @total_cost = @sogou_body[:total_cost]
        @total_pay = @sogou_body[:total_pay]
        
      else
        data = {:message => "API Info not correct", :status => "false"} 
        return render :json => data, :status => :ok
      end
      
    elsif @network_type.to_s == "360"
      
        @apisecret = params[:apisecret]
        if @apisecret.nil? || @apisecret.to_s == ""
          data = {:message => "You must input all API Info.", :status => "false"}
          return render :json => data, :status => :ok
        end
        
        login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
        @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
        
        if @refresh_token.nil?
            data = {:message => "API Info not correct", :status => "false"}
            return render :json => data, :status => :ok
        end
        
        
        @account_info = threesixty_api( @apitoken, @refresh_token, "account", "getInfo", nil)
        @account_info = @account_info["account_getInfo_response"] 
        
        @accountid = @account_info["uid"]
        @email = @account_info["email"]
        @category = @account_info["category"]
        @industry1 = @account_info["industry1"]
        @industry2 = @account_info["industry2"]
        @balance = @account_info["balance"]
        # @budget = @account_info["budget"]
        @mvBudget = @account_info["mvBudget"]
        @resources = @account_info["resources"]
        @domains = @account_info["allowDomain"]
        @mobile_domains = @account_info["allowMobileDomain"]
        @status = @account_info["status"]
         
    else
      data = {:message => "sogou/360 only, for now", :status => "false"}
      return render :json => data, :status => :ok
    end
    
    @network_id = last_network_id.to_i + 1
    
    @db[:network_user].insert_one({ network_id: @network_id.to_i,
                                    user: session[:user_id].to_i })
    
    
    @db.close
                               
    @db[:network].insert_one({ id: @network_id.to_i,
                               name:@network_name.to_s, 
                               type:@network_type.to_s, 
                               company_id: @user_company_id.to_i, 
                               username: @username.to_s, 
                               password: @password.to_s, 
                               api_token: @apitoken.to_s, 
                               tracking_type: @tracking_type.to_s, 
                               currency: @currency.to_s, 
                               ad_redirect: @ad_redirect.to_s,
                               keyword_redirect: @keyword_redirect.to_s,
                               cookie_length: @cookie_length.to_s,
                               create_date: @now })
                               
    @db.close
    
    if @network_type.to_s == "sogou"
      @db[:network].find(id: @network_id.to_i).update_one('$set'=> { 'accountid' => @accountid.to_i,
                                                                      'balance' => @balance.to_f,
                                                                      'budget' => @budget.to_f,
                                                                      'domains' => @domains.to_s,
                                                                      'regions' => @regions,
                                                                      'total_cost' => @total_cost.to_f,
                                                                      'total_pay' => @total_pay.to_f,
                                                                      'quota' => @quota.to_i,
                                                                      'file_update_1' => 0,
                                                                      'file_update_2' => 0,
                                                                      'file_update_3' => 0,
                                                                      'file_update_4' => 0,
                                                                      'tmp_file' => "",
                                                                      'fileid' => ""                                                                       
                                                                    })
       @db.close                                                             
                                                                    
    end
    
    
    if @network_type.to_s == "360"
      
      @db[:network].find(id: @network_id.to_i).update_one('$set'=> {  'api_secret' => @apisecret.to_s,
                                                                      'accountid' => @accountid.to_i,
                                                                      'email' => @email.to_s,
                                                                      'category' => @category.to_s,
                                                                      'industry1' => @industry1.to_s,
                                                                      'industry2' => @industry2.to_s,
                                                                      'resources' => @resources.to_s,
                                                                      'balance' => @balance.to_f,
                                                                      'budget' => @budget.to_f,
                                                                      'mvbudget' => @mvBudget.to_f,
                                                                      'domains' => @domains.to_s,
                                                                      'mobile_domains' => @mobile_domains.to_s,
                                                                      'status' => @status.to_s,
                                                                      'file_update_1' => 0,
                                                                      'file_update_2' => 0,
                                                                      'file_update_3' => 0,
                                                                      'file_update_4' => 0,
                                                                      'tmp_file' => "",
                                                                      'fileid' => ""                                                                       
                                                                    })
                                                                    
                                                                    
       @db.close                                                             
    end
    
    
    update_last_id("network",@network_id)
    
    data = {:message => "Done", :status => "true", :param => params}
    return render :json => data, :status => :ok
                               
  end
  
  def clickactivity
      @type = params[:type]
      @id = params[:id]
  end
  
  def getclickactivity
    
      type = params[:clickactivity_type]
      id = params[:clickactivity_id]
      @csv = params[:csv]
      
      @draw = params[:draw]
      @skip_data = params[:start]
      @length = params[:length]
      session[:length] = params[:length]
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      
      
      if type.to_s == "company" && id.to_i != @user_company_id.to_i
          data = {:message => "Hack ID", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      if type.nil? || id.nil?
          data = {:message => "Missing Type or ID", :status => "false", :type => type, :id => id}
          return render :json => data, :status => :ok
      end
      
      
      @order = params[:order]
      @filter_object = params[:filter_object]
      
      if @length.nil?
          @length = 5
      end
      
      if @end_date.nil?
          request_start_date = @today
          @end_date = request_start_date.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      else
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @start_date = request_start_date.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      else
          @start_date = @start_date.to_date
          @start_date = @start_date.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      end
      
      all_click_array = []
      network_name_hash = {}
      network_type_hash = {}
      
      all_campaign_hash = {}
      all_adgroup_hash = {}
      all_ad_hash = {}
      all_keyword_hash = {}
      conversion_hash = {}
      
      
      
      
      all_network_id_array = []
      all_campaign_array = []
      all_adgroup_array = []
      all_ad_array = []
      all_keyword_array = []
          
          
      if type.to_s == "company"
          @click_count = @db2[:clicks].find("company_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s })
          @db2.close
          
          if @csv.to_i == 1
              @click = @db2[:clicks].find("company_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s })
          else
              @click = @db2[:clicks].find("company_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s }).sort({ date: -1 }).skip(@skip_data.to_i).limit(@length.to_i)
          end
          
          @db2.close
      end
      
      if type.to_s == "campaign"
          @click_count = @db2[:clicks].find("campaign_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s })
          @db2.close
          
          if @csv.to_i == 1
              @click = @db2[:clicks].find("campaign_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s })
          else
              @click = @db2[:clicks].find("campaign_id" => id.to_i, 'network_id' => { "$gt" => 0 }, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s }).sort({ date: -1 }).skip(@skip_data.to_i).limit(@length.to_i)
          end
          
          @db2.close
      end
          
      array_data = []
      csv_array = []
      
      if @click.count.to_i > 0
          @click.each do |click_d|
                all_click_array << click_d
                all_network_id_array << click_d['network_id']
                all_campaign_array << click_d['campaign_id']
                all_adgroup_array << click_d['adgroup_id']
                all_ad_array << click_d['ad_id']
                all_keyword_array << click_d['keyword_id']
          end
      end
      
      all_network_id_array = all_network_id_array.uniq
      all_campaign_array = all_campaign_array.uniq
      all_adgroup_array = all_adgroup_array.uniq
      all_ad_array = all_ad_array.uniq
      all_keyword_array = all_keyword_array.uniq
      
            
      @network = @db[:network].find('id' => { "$in" => all_network_id_array})
      @db.close
      
      if @network.count.to_i > 0
          @network.each do |network_d|
              network_name_hash["id"+network_d["id"].to_s] = network_d['name'].to_s
              network_type_hash["id"+network_d["id"].to_s] = network_d['type'].to_s
          end
      end
      
      @campaign = @db[:all_campaign].find({ "$or" => [{:cpc_plan_id => { "$in" => all_campaign_array}}, {:campaign_id => { "$in" => all_campaign_array}}] })
      @db.close
      
      if @campaign.count.to_i > 0
          @campaign.each do |campaign_d|
              if campaign_d['network_type'].to_s == "sogou"
                  all_campaign_hash["id"+campaign_d["cpc_plan_id"].to_s] = campaign_d['campaign_name'].to_s  
              elsif campaign_d['network_type'].to_s == "360"
                  all_campaign_hash["id"+campaign_d["campaign_id"].to_s] = campaign_d['campaign_name'].to_s
              end
          end
      end
      
      @adgroup = @db3[:sogou_report_adgroup].find(:cpc_grp_id => { "$in" => all_adgroup_array})
      @db3.close
      
      if @adgroup.count.to_i > 0
          @adgroup.each do |adgroup_d|
              all_adgroup_hash["id"+adgroup_d["cpc_grp_id"].to_s] = adgroup_d['cpc_grp_name'].to_s  
          end
      end
      
      @adgroup = @db3[:report_adgroup_360].find(:cpc_grp_id => { "$in" => all_adgroup_array})
      @db3.close
      
      if @adgroup.count.to_i > 0
          @adgroup.each do |adgroup_d|
              all_adgroup_hash["id"+adgroup_d["cpc_grp_id"].to_s] = adgroup_d['cpc_grp_name'].to_s  
          end
      end
      
      @keyword = @db3[:sogou_report_keyword].find(:keyword_id => { "$in" => all_keyword_array})
      @db3.close
      
      if @keyword.count.to_i > 0
          @keyword.each do |keyword_d|
              all_keyword_hash["id"+keyword_d["keyword_id"].to_s] = keyword_d['keyword'].to_s  
          end
      end
      
      @keyword = @db3[:report_keyword_360].find(:keyword_id => { "$in" => all_keyword_array})
      @db3.close
      
      if @keyword.count.to_i > 0
          @keyword.each do |keyword_d|
              all_keyword_hash["id"+keyword_d["keyword_id"].to_s] = keyword_d['keyword'].to_s  
          end
      end
      
      
     
      
      @all_conversion = @db2[:conversion].find.aggregate([ 
                                                   { '$match' => { 'keyword_id' => { "$in" => all_keyword_array}, 'date' => { '$gte' => @start_date.to_s, '$lt' => @end_date.to_s } } },
                                                   { '$group' => { '_id' => '$keyword_id', 'conversion' => { '$sum' => 1 }, 'revenue' => { '$sum' => '$revenue' } } }
                                                ])
      @db2.close      
      
      if @all_conversion.count.to_i > 0 
          @all_conversion.each do |all_conversion_arr|
              conversion_hash["id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['conversion'].to_i
              conversion_hash["id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
          end
      end 
             
      
      # data = {:status => "true", :all_conversion => @all_conversion, :all_keyword_array => all_keyword_array, :s => @start_date, :e => @end_date}
      # return render :json => data, :status => :ok
            
      if all_click_array.count.to_i > 0
            all_click_array.each do |click_d|
              
                @network_id = click_d["network_id"]
                
                @campaign_id = click_d["campaign_id"]
                @adgroup_id = click_d["adgroup_id"]
                @ad_id = click_d["ad_id"]
                @keyword_id = click_d["keyword_id"]
                
                
                # @ad_name = click_d["ad_id"]
                
                if network_name_hash["id"+click_d["network_id"].to_s]
                    @network_name = network_name_hash["id"+click_d["network_id"].to_s]
                else
                    @network_name = @network_id
                end
                
                @network_type = network_type_hash["id"+click_d["network_id"].to_s]
                
                if all_campaign_hash["id"+click_d["campaign_id"].to_s]
                    @campaign_name = all_campaign_hash["id"+click_d["campaign_id"].to_s]
                else
                    @campaign_name = click_d["campaign_id"]
                end
                
                if all_adgroup_hash["id"+click_d["adgroup_id"].to_s]
                    @adgroup_name = all_adgroup_hash["id"+click_d["adgroup_id"].to_s]
                else
                    @adgroup_name = click_d["adgroup_id"]
                end
                    
                if all_keyword_hash["id"+click_d["keyword_id"].to_s]    
                    @keyword_name = all_keyword_hash["id"+click_d["keyword_id"].to_s]
                else
                    @keyword_name = click_d["keyword_id"]
                end
                
                if conversion_hash["id"+click_d["keyword_id"].to_s]
                    @total_conversion = conversion_hash["id"+click_d["keyword_id"].to_s]
                else
                    @total_conversion = 0
                end
                
                if conversion_hash["id"+click_d["keyword_id"].to_s+"revenue"]
                    @total_revenue = conversion_hash["id"+click_d["keyword_id"].to_s+"revenue"]
                else
                    @total_revenue = 0
                end
                
                # if @network_type.to_s == "sogou"
                      
                      # db_name = "keyword_sogou_"+@network_id.to_s
                      # @keyword_sogou = @db[db_name].find("keyword_id" => click_d["keyword_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @keyword_sogou.count.to_i > 0
                          # @keyword_sogou.each do |keyword_sogou|
                              # @keyword_name = keyword_sogou["keyword"]
                          # end  
                      # end
#                       
                      # db_name = "ad_sogou_"+@network_id.to_s
                      # @ad_sogou = @db[db_name].find("cpc_idea_id" => click_d["ad_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @ad_sogou.count.to_i > 0
                          # @ad_sogou.each do |ad_sogou|
                               # @ad_name = ad_sogou["title"]
                          # end
                      # end
#                       
                      # db_name = "adgroup_sogou_"+@network_id.to_s
                      # @adgroup_sogou = @db[db_name].find("cpc_grp_id" => click_d["adgroup_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @adgroup_sogou.count.to_i > 0
                          # @adgroup_sogou.each do |adgroup_sogou|
                               # @adgroup_name = adgroup_sogou["name"]
                          # end
                      # end
#                       
                      # @campaign_sogou = @db["all_campaign"].find("cpc_plan_id" => click_d["campaign_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @campaign_sogou.count.to_i > 0
                          # @campaign_sogou.each do |campaign_sogou|
                               # @campaign_name = campaign_sogou["name"]
                          # end
                      # end
                # end
                
                
                
                # if @network_type.to_s == "360"
                      
                      # db_name = "keyword_360_"+@network_id.to_s
                      # @keyword_360 = @db[db_name].find("keyword_id" => click_d["keyword_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @keyword_360.count.to_i > 0
                          # @keyword_360.each do |keyword_360|
                              # @keyword_name = keyword_360["keyword"]
                          # end  
                      # end
#                       
                      # db_name = "ad_360_"+@network_id.to_s
                      # @ad_360 = @db[db_name].find("ad_id" => click_d["ad_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @ad_360.count.to_i > 0
                          # @ad_360.each do |ad_360|
                               # @ad_name = ad_360["title"]
                          # end
                      # end
#                       
                      # db_name = "adgroup_360_"+@network_id.to_s
                      # @adgroup_360 = @db[db_name].find("adgroup_id" => click_d["adgroup_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @adgroup_360.count.to_i > 0
                          # @adgroup_360.each do |adgroup_360|
                               # @adgroup_name = adgroup_360["adgroup_name"]
                          # end
                      # end
#                       
#                       
                      # # db_name = "campaign_360_"+@network_id.to_s
                      # # @campaign_360 = @db[db_name].find("campaign_id" => click_d["campaign_id"].to_i).limit(1)
#                       
                      # @campaign_360 = @db["all_campaign"].find("campaign_id" => click_d["campaign_id"].to_i).limit(1)
                      # @db.close
#                       
                      # if @campaign_360.count.to_i > 0
                          # @campaign_360.each do |campaign_360|
                               # @campaign_name = campaign_360["campaign_name"]
                          # end
                      # end
                # end
                 
                # @conversion = @db2[:conversion].find("id" => click_d['id'])
                # @db2.close
                # @total_conversion = @conversion.count.to_i 
                
                
                if @csv.to_i == 1
                    # csv_array << [@network_type.to_s,@network_name.to_s,@campaign_id.to_s,@campaign_name.to_s, @adgroup_id.to_s,@adgroup_name.to_s,@ad_id.to_s,@ad_name.to_s, @keyword_id.to_s,@keyword_name.to_s,click_d["search_q"].to_s, click_d["ip"].to_s,click_d["country"].to_s,click_d["city"].to_s,click_d["user_agent"].to_s,click_d["variant"].to_s,click_d["cookies"].to_s,click_d["other_parameters"].to_s,click_d["date"].to_s,click_d["referer"].to_s,click_d["destination_url"].to_s]
                    csv_array << [click_d["date"].to_s,@network_type.to_s,@network_name.to_s,@campaign_name.to_s,@adgroup_name.to_s,@keyword_name.to_s,click_d["search_q"].to_s,@total_conversion.to_i,click_d["user_agent"],click_d["variant"].to_s,click_d["country"].to_s,click_d["city"].to_s,@ad_name.to_s,@campaign_id.to_s,@adgroup_id.to_s,@ad_id.to_s,@keyword_id.to_s,click_d["ip"].to_s,click_d["cookies"].to_s,click_d["other_parameters"].to_s,click_d["referer"].to_s,click_d["destination_url"].to_s]
                else
                    array_data << [click_d["date"].to_s,@network_type.to_s,@network_name.to_s,@campaign_name.to_s,@adgroup_name.to_s,@keyword_name.to_s,click_d["search_q"].to_s,@total_conversion.to_i,click_d["user_agent"],click_d["variant"].to_s,click_d["country"].to_s,click_d["city"].to_s,@ad_name.to_s,@campaign_id.to_s,@adgroup_id.to_s,@ad_id.to_s,@keyword_id.to_s,click_d["ip"].to_s,click_d["cookies"].to_s,click_d["other_parameters"].to_s,click_d["referer"].to_s,click_d["destination_url"].to_s,click_d['network_type'],click_d['id']]
                end
            end
      end
      
         
      
      
      if @csv.to_i == 1
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            # @filename = @user_company_name.to_s.downcase + "_" + type + "_"+ id +"_click_activity_(" +@start_date+"-"+@end_date+")"
            
            @filename = "click_activity_"+@network_name.to_s+"_"+@campaign_name.to_s+"_(" +@start_date+"-"+@end_date+")"
            
            head = ["\xEF\xBB\xBFDate","\xEF\xBB\xBFChannel","\xEF\xBB\xBFAccount","\xEF\xBB\xBFCampaign","\xEF\xBB\xBFAdgroup", "\xEF\xBB\xBFKeyword", "\xEF\xBB\xBFSearch query", "\xEF\xBB\xBFConversions", "\xEF\xBB\xBFUser Agent", "\xEF\xBB\xBFDevice", "\xEF\xBB\xBFCountry", "\xEF\xBB\xBFCity", "\xEF\xBB\xBFAd", "Campaign ID", "Adgroup ID", "Ad ID", "Keyword ID", "IP", "Cookies", "Other Parameters", "Referer", "Destination Url"]
            
            if !@filter_object.nil?
                csv_array = filter_object_click_activity(@filter_object, csv_array)
            end
            
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
            if !@filter_object.nil?
                array_data = filter_object_click_activity(@filter_object, array_data)
            end
        
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                if @sort_method.to_s == "asc"
                    array_data = array_data.sort_by{|k|k[@sort_column.to_i]}
                else
                    array_data = array_data.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
            
            
            data = {:status => "true", :draw => @draw.to_i, :recordsTotal => @click_count.count.to_i, :recordsFiltered => @click_count.count.to_i, :data => array_data}
            return render :json => data, :status => :ok
      end
  end
  
  
  def getcampaignkeyword
    
      begin
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @campaign_type = params[:campaign_type]
      @campaign_id = params[:campaign_id]
      @network_id = params[:network_id]
      
      @adgroup_id = params[:adgroup_id]
      
      @skip_data = params[:start]
      @length = params[:length]
      session[:length] = params[:length]
      
      @csv = params[:csv]
      
      @account_array = params[:account_array]
      
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      if @campaign_id.nil? || @campaign_type.nil?
          data = {:message => "Your data is updating, please come back later.", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      # @logger.info "Load Network getcampaignkeyword, campaign id: "+ @campaign_id.to_s+ "campaign type: "+@campaign_type+ " "+ @now.to_s
      
      @order = params[:order]
      @filter_object = params[:filter_object]
      
      if @length.nil?
          @length = 5
      end
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
      
            
      data_array = []
      csv_array = []
      
      @network = @db["network"].find('id' => @network_id.to_i).limit(1)
      @db.close
      
      @network.each do |network_d|
          @network_name = network_d["name"]
      end
      
             
      if @campaign_type.to_s == "sogou"
              
              @campaign = @db["all_campaign"].find('cpc_plan_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                  @campaign_title = campaign["campaign_name"]
              end
              
              @adgroup_title = ""
              
              arr = []  
              adg_arr = []
              
              db_name = "keyword_sogou_"+@network_id.to_s
              adgroup_db_name = "adgroup_sogou_"+@network_id.to_s
              
              if @adgroup_id.to_i > 0
                  @keyword_count = @db[db_name].find('cpc_plan_id' => @campaign_id.to_i,'cpc_grp_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup = @db[adgroup_db_name].find('cpc_grp_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup.each do |adgroup|
                      @adgroup_title = adgroup["name"].to_s 
                  end
              else
                  @keyword_count = @db[db_name].find('cpc_plan_id' => @campaign_id.to_i)
                  @db.close
              end
              
              if @keyword_count.count.to_i >= 100000 && @filter_object.nil? && @csv.to_i == 0
                  data = {:recordsTotal => 0, :recordsFiltered => 0, :data => {}, :message => "Your Keyword has more than 100000 record, try use the Advanced Filter or view this under specific Ad group.", :status => "false"}
                  return render :json => data, :status => :ok  
              end
              
              @keyword_count.each do |keyword_count|
                  arr << keyword_count["keyword_id"]  
                  adg_arr << keyword_count["cpc_grp_id"]
              end
              
              adg_arr = adg_arr.uniq
              
              sogou_report_hash = {}
              
              @sogou_report_keyword = @db3[:sogou_report_keyword].find('keyword_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
              @db3.close
              
              if @sogou_report_keyword.count.to_i > 0
                  @sogou_report_keyword.each do |sogou_report_keyword|
                  
                      if sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"display"]
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"display"] += sogou_report_keyword['display'].to_i
                      else
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"display"] = sogou_report_keyword['display'].to_i
                      end
                      
                      if sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"clicks"]
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"clicks"] += sogou_report_keyword['clicks'].to_i
                      else
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"clicks"] = sogou_report_keyword['clicks'].to_i
                      end
                      
                      if sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"total_cost"]
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"total_cost"] += sogou_report_keyword['total_cost'].to_f
                      else
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"total_cost"] = sogou_report_keyword['total_cost'].to_f
                      end
                      
                      if sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"avg_position"]
                          avg_pos = sogou_report_keyword["avg_position"].to_f * sogou_report_keyword["display"].to_f
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"avg_position"] += avg_pos.to_f
                      else
                          sogou_report_hash["keyword_id"+sogou_report_keyword['keyword_id'].to_s+"avg_position"] = sogou_report_keyword['avg_position'].to_f * sogou_report_keyword['display'].to_f
                      end
                  
                  end
              end
              
              conversion_hash = {}
              
              conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
              @end_date = @end_date.to_date - 1.days
              conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
              
              
              @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'keyword_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "sogou" } },
                               { '$group' => { '_id' => '$keyword_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
              @db2.close
              
              
              if @all_conversion.count.to_i > 0 
                  @all_conversion.each do |all_conversion_arr|
                      conversion_hash["keyword_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                      conversion_hash["keyword_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                  end
              end
              
              
              # @all_conversion = @db2[:conversion].find('network_type' => "sogou",'keyword_id' => {"$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
              # @db2.close
#               
              # if @all_conversion.count.to_i > 0 
                  # @all_conversion.each do |all_conversion_arr|
                      # if conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s]
                          # conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s] += 1
                      # else
                          # conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s] = 1
                      # end
                  # end
              # end
              
              adgroup_name_hash = {}
              
              db_name = "adgroup_sogou_"+@network_id.to_s
              @sogou_adgroup = @db[db_name].find('cpc_grp_id' => { "$in" => adg_arr}) 
              @db.close
              
              if @sogou_adgroup.count.to_i != 0
                  @sogou_adgroup.each do |adgroup|
                      # @name = adgroup["name"]
                      
                      adgroup_name_hash["adgroup_id"+adgroup['cpc_grp_id'].to_s+"adgroup_name"] = adgroup["name"]
                  end
              end
              
              
              
              
              if @keyword_count.count.to_i >0
                    @keyword_count.each do |keyword_d|
                      
                                  # # @logger.info "keyword id: "+keyword_d.to_s+ " "+ @now.to_s
                                  @status = "Active"
                                  @pause = "Active"
                                  
                                  if keyword_d["status"].to_i == 31
                                      @status = "Invalid"  
                                  end
                                  
                                  if keyword_d["status"].to_i == 32
                                      @status = "Inactive"  
                                  end
                                  
                                  if keyword_d["status"].to_i == 33
                                      @status = "Under Approval"  
                                  end
                                  
                                  if keyword_d["status"].to_i == 34
                                      @status = "Search Invalid"  
                                  end
                                  
                                  if keyword_d["status"].to_i == 36
                                      @status = "Desktop Search Invalid"  
                                  end
                                  
                                  if keyword_d["status"].to_i == 37
                                      @status = "Mobile Search Invalid"  
                                  end
                                  
                                  if keyword_d["pause"].to_s.downcase == "true"
                                      @pause = "Inactive"
                                  end
                                  
                                  if keyword_d["pause"].to_s.downcase == "false"
                                      @pause = "Active"
                                  end
                                
                                   
                                  @impression = 0
                                  @total_cost = 0
                                  @click = 0
                                  @click_rate = 0
                                  @cpc = 0
                                  @max_cpc = 0
                                  
                                  @conv_rate = 0
                                  @cpa = 0
                                  
                                  @avg_pos = 0
                                  
                                  
                                  if sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"display"]
                                      @impression = sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"display"]
                                  else
                                      @impression = 0
                                  end
                                  
                                  if sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"clicks"]
                                      @click = sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"clicks"]
                                  else
                                      @click = 0
                                  end
                                  
                                  if sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"total_cost"]
                                      @total_cost = sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"total_cost"]
                                  else
                                      @total_cost = 0
                                  end
                                  
                                  if sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"avg_position"]
                                      @avg_pos = sogou_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"avg_position"]
                                  else
                                      @avg_pos = 0
                                  end
                                  
                                  @name = adgroup_name_hash["adgroup_id"+keyword_d['cpc_grp_id'].to_s+"adgroup_name"].to_s
                                  
                                  if @impression.to_f > 0
                                      @click_rate = (@click.to_f / @impression.to_f) * 100
                                  end
                                  
                                  if @click.to_f > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  if @avg_pos > 0 && @impression > 0
                                    @avg_pos = @avg_pos.to_f / @impression.to_f
                                  end
                                  
                                  
                                  if keyword_d["match_type"].to_i == 0
                                      @match = "Exact Match"
                                  elsif keyword_d["match_type"].to_i == 1
                                      @match = "Broad Match"
                                  else
                                      @match = "Phrase Match"
                                  end
                                  
                                  
                                  @visit_url = keyword_d["visit_url"].to_s
                                  @m_visit_url = keyword_d["mobile_visit_url"].to_s
                                  
                                  @visit_url_durl = @visit_url
                                  @m_visit_url_durl = @m_visit_url
                                  
                                  if @visit_url.to_s != "" && @visit_url.include?(".adeqo.")
                                      @visit_url_durl_array = @visit_url.to_s.split("durl=")
                                      if !@visit_url_durl_array[1].nil?
                                          @visit_url_durl = CGI.unescape(@visit_url_durl_array[1].to_s) 
                                      end 
                                  end
                                  
                                  if @m_visit_url.to_s != "" && @m_visit_url.include?(".adeqo.")
                                      @m_visit_url_durl_array = @m_visit_url.to_s.split("durl=")
                                      if !@m_visit_url_durl_array[1].nil?
                                          @m_visit_url_durl = CGI.unescape(@m_visit_url_durl_array[1]) 
                                      end
                                  end
                                   
                                  # @visit_url = CGI.unescape(keyword_d["visit_url"]).to_s
                                  # @m_visit_url = CGI.unescape(keyword_d["mobile_visit_url"]).to_s
#                                   
                                  # @visit_url = @visit_url.gsub("&amp;", "&")
                                  # @m_visit_url = @m_visit_url.gsub("&amp;", "&")
                                  
                                  @data_conversion = conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s]
                                   
                                  if @data_conversion.to_i > 0
                                      if @click.to_f > 0
                                          @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                                      end
                                      
                                      if @total_cost.to_f > 0
                                          @cpa = @total_cost.to_f / @data_conversion.to_f
                                      end
                                  end
                                  
                                  if @total_cost > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+keyword_d["cpc_grp_id"].to_s+"/keyword"
                                  
                                  if @csv.to_i == 1         
                                      csv_array << [keyword_d["keyword_id"].to_i,@pause.to_s,@name.to_s,keyword_d["cpc_grp_id"].to_i,@campaign_title.to_s,@campaign_id.to_i,@campaign_type.to_s,@network_id.to_i,@network_name.to_s,keyword_d["keyword"].to_s,@match.to_s,@visit_url_durl.to_s,@m_visit_url_durl.to_s,keyword_d["price"].to_f,@impression.to_f,@click.to_f,@click_rate.to_f,@total_cost.to_f,@cpc.to_f, @data_conversion.to_i, @conv_rate.to_f,  @cpa.to_f, 0, conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s+"revenue"].to_f, 0, @avg_pos.to_f,0,0]
                                  else
                                      data_array << [keyword_d["keyword_id"].to_i,@status.to_s,@name.to_s, keyword_d["keyword"].to_s,@match.to_s,@visit_url_durl.to_s,@m_visit_url_durl.to_s,keyword_d["price"].to_f,@impression.to_f,@click.to_f,@click_rate.to_f,@total_cost.to_f,@cpc.to_f, @data_conversion.to_i, @conv_rate.to_f,  @cpa.to_f, 0, conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s+"revenue"].to_f, 0,@avg_pos.to_f,0,0,@visit_url.to_s,@m_visit_url.to_s,@link]
                                  end
                    end
              end
      end
      
      if @campaign_type.to_s == "threesixty"
              
              
              @campaign = @db["all_campaign"].find('campaign_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
              
              arr = []  
              adg_arr = []
              
              @adgroup_title = ""
              
              db_name = "keyword_360_"+@network_id.to_s
              adgroup_db_name = "adgroup_360_"+@network_id.to_s
              
              if @adgroup_id.to_i > 0
                  @keyword_count = @db[db_name].find('campaign_id' => @campaign_id.to_i,'adgroup_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup = @db[adgroup_db_name].find('adgroup_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup.each do |adgroup|
                      @adgroup_title = adgroup["adgroup_name"]
                  end
              else
                  @keyword_count = @db[db_name].find('campaign_id' => @campaign_id.to_i)
                  @db.close
              end
              
              if @keyword_count.count.to_i >= 100000 && @filter_object.nil? && @csv.to_i == 0
                  data = {:recordsTotal => 0, :recordsFiltered => 0, :data => {}, :message => "Your Keyword has more than 100000 record, try use the Advanced Filter or view this under specific Ad group.", :status => "false"}
                  return render :json => data, :status => :ok  
              end
              
              @keyword_count.each do |keyword_count|
                  arr << keyword_count["keyword_id"]  
                  adg_arr << keyword_count["adgroup_id"]
              end
              
              threesixty_report_hash = {}
              @report_keyword_360 = @db3[:report_keyword_360].find('keyword_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'views' => { "$gt" => 0})
              @db3.close
              
              

              if @report_keyword_360.count.to_i > 0
                  @report_keyword_360.each do |report_keyword_360|
                    
                      if threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"views"]
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"views"] += report_keyword_360['views'].to_i
                      else
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"views"] = report_keyword_360['views'].to_i
                      end
                      
                      
                      if threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"clicks"]
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"clicks"] += report_keyword_360['clicks'].to_i
                      else
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"clicks"] = report_keyword_360['clicks'].to_i
                      end
                      
                      if threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"total_cost"]
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"total_cost"] += report_keyword_360['total_cost'].to_f
                      else
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"total_cost"] = report_keyword_360['total_cost'].to_f
                      end
                      
                      
                      if threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"avg_position"]
                        
                          avg_pos = report_keyword_360["avg_position"].to_f * report_keyword_360["views"].to_f
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"avg_position"] += avg_pos.to_f
                      else
                          threesixty_report_hash["keyword_id"+report_keyword_360['keyword_id'].to_s+"avg_position"] = report_keyword_360['avg_position'].to_f * report_keyword_360['views'].to_f
                      end
                      
                  end
              end
                         
              conversion_hash = {}
              
              conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
              @end_date = @end_date.to_date - 1.days
              conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
              
              
              
              @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'keyword_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "360" } },
                               { '$group' => { '_id' => '$keyword_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
              @db2.close
              
              
              if @all_conversion.count.to_i > 0 
                  @all_conversion.each do |all_conversion_arr|
                      conversion_hash["keyword_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                      conversion_hash["keyword_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                  end
              end
              
              
              # @all_conversion = @db2[:conversion].find('network_type' => "360",'keyword_id' => {"$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
              # @db2.close   
#               
              # if @all_conversion.count.to_i > 0 
                  # @all_conversion.each do |all_conversion_arr|
#                       
                      # if conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s]
                          # conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s] += 1
                      # else
                          # conversion_hash["keyword_id"+all_conversion_arr['keyword_id'].to_s] = 1
                      # end
                  # end
              # end
              
                      
              
              adgroup_name_hash = {}
              
              db_name = "adgroup_360_"+@network_id.to_s
              @adgroup_360 = @db[db_name].find('adgroup_id' => { "$in" => adg_arr})
              @db.close
              
              if @adgroup_360.count.to_i != 0
                  @adgroup_360.each do |adgroup|
                      adgroup_name_hash["adgroup_id"+adgroup['adgroup_id'].to_s+"adgroup_name"] = adgroup["adgroup_name"]
                  end
              end
                                  
              
          
              if @keyword_count.count.to_i >0
                    @keyword_count.each do |keyword_d|
                                  # # @logger.info "keyword id: "+keyword_d.to_s+ " "+ @now.to_s

                                  @status = "Active"
                                  
                                  if keyword_d["status"].to_s == "暂停"
                                      @status = "Inactive"  
                                  end
                                  
                                  if @status.to_s == "Inactive" && keyword_d["sys_status"].to_s != "有效"
                                      @status = "Invalid"  
                                  end
                                  
                                  @match = "Exact Match"
                                  
                                  if keyword_d["match_type"].to_s == "短语"
                                      @match = "Phrase Match"
                                  end
                                  
                                  @visit_url = keyword_d["visit_url"].to_s
                                  @m_visit_url = keyword_d["mobile_visit_url"].to_s
                                  
                                  @visit_url_durl = @visit_url
                                  @m_visit_url_durl = @m_visit_url
                                  
                                  if @visit_url.to_s != "" && @visit_url.include?(".adeqo.")
                                      @visit_url_durl_array = @visit_url.to_s.split("durl=")
                                      if !@visit_url_durl_array[1].nil?
                                          @visit_url_durl = CGI.unescape(@visit_url_durl_array[1].to_s)
                                      end 
                                  end
                                  
                                  if @m_visit_url.to_s != "" && @m_visit_url.include?(".adeqo.")
                                      @m_visit_url_durl_array = @m_visit_url.to_s.split("durl=")
                                      if !@m_visit_url_durl_array[1].nil?
                                          @m_visit_url_durl = CGI.unescape(@m_visit_url_durl_array[1])
                                      end
                                  end

                                   
                                  @impression = 0
                                  @total_cost = 0
                                  @click = 0
                                  @click_rate = 0
                                  @cpc = 0
                                  @max_cpc = 0
                                  @conv_rate = 0
                                  @cpa = 0
                                  
                                  @avg_pos = 0
                                  
                                  
                                  if threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"views"]
                                      @impression = threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"views"]
                                  else
                                      @impression = 0
                                  end
                                  
                                  
                                  if threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"clicks"]
                                      @click = threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"clicks"]
                                  else
                                      @click = 0
                                  end
                                  
                                  if threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"total_cost"]
                                      @total_cost = threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"total_cost"]
                                  else
                                      @total_cost = 0
                                  end
                                  
                                  if threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"avg_position"]
                                      @avg_pos = threesixty_report_hash["keyword_id"+keyword_d['keyword_id'].to_s+"avg_position"]
                                  else
                                      @avg_pos = 0
                                  end
                                  
                                            
                                  if @impression.to_f > 0
                                      @click_rate = (@click.to_f / @impression.to_f) * 100
                                  end
                                   
                                  if @clicks.to_f > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  if @avg_pos > 0
                                      @avg_pos = @avg_pos.to_f / @impression.to_f
                                  end
                                        
                                   
                                  @name = adgroup_name_hash["adgroup_id"+keyword_d['adgroup_id'].to_s+"adgroup_name"].to_s
                                  
                                  
                                  @data_conversion = conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s]
                                  
                                  if @data_conversion.to_i > 0
                                    
                                      if @click > 0
                                        @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                                      end
                                      
                                      if @total_cost > 0
                                        @cpa = @total_cost.to_f / @data_conversion.to_f
                                      end
                                  end
                                  
                                  if @total_cost > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+keyword_d["adgroup_id"].to_s+"/keyword"
                                  
                                  if @csv.to_i == 1     
                                      csv_array << [keyword_d["keyword_id"].to_i,@status.to_s,@name.to_s,keyword_d["adgroup_id"].to_s,@campaign_title.to_s,@campaign_id.to_s,@campaign_type.to_s,@network_id.to_s, @network_name.to_s, keyword_d["keyword"].to_s,@match.to_s,@visit_url_durl.to_s,@m_visit_url_durl.to_s,keyword_d["price"].to_f,@impression.to_f,@click.to_f,@click_rate.to_f,@total_cost.to_f,@cpc.to_f, @data_conversion.to_i, @conv_rate.to_f,  @cpa.to_f, 0, conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s+"revenue"].to_f, 0, @avg_pos.to_f ,0,0]
                                  else      
                                      data_array << [keyword_d["keyword_id"].to_i,@status.to_s,@name.to_s, keyword_d["keyword"].to_s,@match.to_s,@visit_url_durl.to_s,@m_visit_url_durl,keyword_d["price"].to_f,@impression.to_f,@click.to_f,@click_rate.to_f,@total_cost.to_f,@cpc.to_f, @data_conversion.to_i, @conv_rate.to_f,  @cpa.to_f, 0, conversion_hash["keyword_id"+keyword_d['keyword_id'].to_s+"revenue"].to_f, 0,@avg_pos.to_f,0,0,@visit_url.to_s,@m_visit_url.to_s,@link]
                                  end
                               
                    end
              end
      end
      
      
      
      if @csv.to_i == 1
        
            if !@filter_object.nil?
                csv_array = filter_object_keyword(@filter_object, csv_array)
            end
        
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            if @export_csv_start_date == @export_csv_end_date
                if @adgroup_title.to_s == ""
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-keyword_(" + @export_csv_start_date +")"
                else
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_keyword-under_"+@adgroup_title.to_s+"(" + @export_csv_start_date +")"
                end
            else
                if @adgroup_title.to_s == ""
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-keyword_(" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
                else
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_keyword-under_"+@adgroup_title.to_s+"(" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
                end
            end
            
            head = ["\xEF\xBB\xBFKeyword ID","\xEF\xBB\xBFStatus","\xEF\xBB\xBFAd Group Name","\xEF\xBB\xBFAd Group ID","\xEF\xBB\xBFCampaign Name","\xEF\xBB\xBFCampaign ID","\xEF\xBB\xBFChannel Type","\xEF\xBB\xBFChannel ID","\xEF\xBB\xBFChannel Name","\xEF\xBB\xBFKeyword","Match Type","Landing page Url","Mobile Landing page Url","Default Max. CPC","Impr.","Clicks","CTR","Cost","Avg. CPC","Conversions","Conv. Rate","CPA","CPM","Revenue","Profit","Avg.pos","RPA","ROAS"]
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
            if !@filter_object.nil?
                data_array = filter_object_keyword(@filter_object, data_array)
            end
            
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                # 1: "status" 
                # 3: ad group name
                # 4: keyword
                # 5: match type
                # 6: fonal url
                # 7: ad type
                # 8: drfault max cpc
                # 9: avg cpc
                # 10: impression
                # 11: clicks
                # 12: ctr
                # 13: cost
                # 14: conversion
                # 15: conv rate
                # 16: cpa
                # 17: cpm
                # 18: revenue
                # 19: profit
                # 20: avg pos
                # 21: rpa
                # 22: roas
                
                if @sort_method.to_s == "asc"
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                else
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
            
            
            data = {:recordsTotal => data_array.count.to_i, :recordsFiltered => data_array.count.to_i, :data => data_array.drop(@skip_data.to_i).first(@length.to_i)}
            return render :json => data, :status => :ok
      end
      rescue Exception
          data = {:message => "Our System is updating, please come back later.", :status => "false"}
          return render :json => data, :status => :ok
      end
  end
  
  
  def getcampaignads
      
      begin
        
      
        
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @campaign_type = params[:campaign_type]
      @campaign_id = params[:campaign_id]
      @network_id = params[:network_id]
      
      @skip_data = params[:start]
      @length = params[:length]
      session[:length] = params[:length]
      
      @csv = params[:csv]
      
      @account_array = params[:account_array]
      
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      @adgroup_id = params[:adgroup_id]
      
      if @campaign_id.nil? || @campaign_type.nil?
          data = {:message => "Your data is updating, please come back later.", :status => "false"}
          return render :json => data, :status => :ok
      end
          
      
      @order = params[:order]
      @filter_object = params[:filter_object]
      
      if @length.nil?
          @length = 5
      end
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
            
      csv_array = []      
      data_array = []
      
      @network = @db["network"].find('id' => @network_id.to_i).limit(1)
      @db.close
      
      @network.each do |network_d|
          @network_name = network_d["name"]
      end
              
      
      if @campaign_type.to_s == "sogou"
              
              @campaign = @db["all_campaign"].find('cpc_plan_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
              
              arr = []  
              adg_arr = []
              
              db_name = "ad_sogou_"+@network_id.to_s
              adgroup_db_name = "adgroup_sogou_"+@network_id.to_s
              
              @adgroup_title = ""
              
              if @adgroup_id.to_i > 0
                  @ad_count = @db[db_name].find('cpc_plan_id' => @campaign_id.to_i,'cpc_grp_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup = @db[adgroup_db_name].find('cpc_grp_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup.each do |adgroup|
                    @adgroup_title = adgroup["name"]
                  end
              else
                  @ad_count = @db[db_name].find('cpc_plan_id' => @campaign_id.to_i)
                  @db.close
              end
              
              if @ad_count.count.to_i >= 80000 && @filter_object.nil? && @csv.to_i == 0
                  data = {:recordsTotal => 0, :recordsFiltered => 0, :data => {}, :message => "Your Ad has more than 80000 record, try use the Advanced Filter or view this under specific Ad group.", :status => "false"}
                  return render :json => data, :status => :ok  
              end
              
              @ad_count.each do |ad_count|
                  arr << ad_count["cpc_idea_id"]  
                  adg_arr << ad_count["cpc_grp_id"]
              end
              
              adg_arr = adg_arr.uniq
              
              sogou_report_hash = {}
              @sogou_report_ad = @db3[:sogou_report_ad].find('ad_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
              @db3.close
              
              if @sogou_report_ad.count.to_i > 0
                  @sogou_report_ad.each do |sogou_report_ad|
                    
                      if sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"display"]
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"display"] += sogou_report_ad['display'].to_i
                      else
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"display"] = sogou_report_ad['display'].to_i
                      end
                      
                      if sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"clicks"]
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"clicks"] += sogou_report_ad['clicks'].to_i
                      else
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"clicks"] = sogou_report_ad['clicks'].to_i
                      end
                      
                      if sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"total_cost"]
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"total_cost"] += sogou_report_ad['total_cost'].to_f
                      else
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"total_cost"] = sogou_report_ad['total_cost'].to_f
                      end
                      
                      if sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"avg_position"]
                        
                          if sogou_report_ad['display'].to_f > 0 && sogou_report_ad['avg_position'].to_f > 0
                              avg_pos = sogou_report_ad["avg_position"].to_f * sogou_report_ad["display"].to_f
                              sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"avg_position"] += avg_pos.to_f
                          end
                          
                      else
                          sogou_report_hash["ad_id"+sogou_report_ad['ad_id'].to_s+"avg_position"] = sogou_report_ad['avg_position'].to_f * sogou_report_ad['display'].to_f
                      end
                  end
              end
              
              
              
              
              conversion_hash = {}
              conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
              @end_date = @end_date.to_date - 1.days
              conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
              
              
              
              @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'ad_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "sogou" } },
                               { '$group' => { '_id' => '$ad_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
              @db2.close
              
              
              if @all_conversion.count.to_i > 0 
                  @all_conversion.each do |all_conversion_arr|
                      conversion_hash["ad_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                      conversion_hash["ad_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                  end
              end
              
              
              
              # @all_conversion = @db2[:conversion].find('network_type' => "sogou",'ad_id' => {"$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
              # @db2.close
#               
              # if @all_conversion.count.to_i > 0 
                  # @all_conversion.each do |all_conversion_arr|
                      # if conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s]
                          # conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s] += 1
                      # else
                          # conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s] = 1
                      # end
                  # end
              # end
              
              
              adgroup_name_hash = {}
              adgroup_price_hash = {}
              
              db_name = "adgroup_sogou_"+@network_id.to_s
              @sogou_adgroup = @db[db_name].find('cpc_grp_id' => { "$in" => adg_arr}) 
              @db.close
              
              if @sogou_adgroup.count.to_i != 0
                  @sogou_adgroup.each do |adgroup|
                      # @name = adgroup["name"]
                      # @max_cpc = adgroup["max_price"]
                      
                      adgroup_name_hash["adgroup_id"+adgroup['cpc_grp_id'].to_s+"adgroup_name"] = adgroup["name"]
                      adgroup_price_hash["adgroup_id"+adgroup['cpc_grp_id'].to_s+"price"] = adgroup["max_price"]
                      
                  end
              end
              
                                  
              
      
              if @ad_count.count.to_i >0
                    @ad_count.each do |ad_d|
                      
                                  @status = "Active"
                                  
                                  if ad_d["status"].to_i == 41
                                      @status = "Invalid"  
                                  end
                                  
                                  if ad_d["status"].to_i == 42
                                      @status = "Inactive"  
                                  end
                                  
                                  if ad_d["status"].to_i == 43
                                      @status = "Under Approval"  
                                  end
                                  
                                  if ad_d["status"].to_i == 45
                                      @status = "Mobile Url Invalid"  
                                  end
                                  
                                   
                                  @impression = 0
                                  @total_cost = 0
                                  @click = 0
                                  @click_rate = 0
                                  @cpc = 0
                                  @max_cpc = 0
                                  @conv_rate = 0
                                  @cpa = 0
                                  
                                  @avg_pos = 0
                                  
                                  
                                  if sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"display"]
                                      @impression = sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"display"]
                                  else
                                      @impression = 0
                                  end
                                  
                                  if sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"clicks"]
                                      @click = sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"clicks"]
                                  else
                                      @click = 0
                                  end
                                  
                                  
                                  
                                  if sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"total_cost"]
                                      @total_cost = sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"total_cost"]
                                  else
                                      @total_cost = 0
                                  end
                                  
                                  if sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"avg_position"]
                                      @avg_pos = sogou_report_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"avg_position"]
                                  else
                                      @avg_pos = 0
                                  end
                                  
                                  
                                  @title = ad_d["title"]
                                  @desc1 = ad_d["description_1"]
                                  @desc2 = ad_d["description_2"]
                                  @visiturl = ad_d["visit_url"]
                                  @showurl = ad_d["show_url"]
                                  @m_visiturl = ad_d["mobile_visit_url"]
                                  @m_showurl = ad_d["mobile_show_url"]
                                  
                                  
                                  @visiturl_durl = @visiturl
                                  @showurl_durl = @showurl
                                  @m_visiturl_durl = @m_visiturl
                                  @m_showurl_durl = @m_showurl
                                  
                                  if @visiturl.to_s != "" && @visiturl.include?(".adeqo.")
                                      @visit_url_durl_array = @visiturl.to_s.split("durl=")
                                      if !@visit_url_durl_array[1].nil?
                                          @visiturl_durl = CGI.unescape(@visit_url_durl_array[1].to_s)
                                      end 
                                  end
                                  
                                  if @showurl.to_s != "" && @showurl.include?(".adeqo.")
                                      @showurl_durl_array = @showurl.to_s.split("durl=")
                                      if !@showurl_durl_array[1].nil?
                                          @showurl_durl = CGI.unescape(@showurl_durl_array[1].to_s)
                                      end 
                                  end
                                  
                                  if @m_visiturl.to_s != "" && @m_visiturl.include?(".adeqo.")
                                      @m_visiturl_durl_array = @m_visiturl.to_s.split("durl=")
                                      if !@m_visiturl_durl_array[1].nil?
                                          @m_visiturl_durl = CGI.unescape(@m_visiturl_durl_array[1].to_s)
                                      end 
                                  end
                                  
                                  if @m_showurl.to_s != "" && @m_showurl.include?(".adeqo.")
                                      @m_showurl_durl_array = @m_showurl.to_s.split("durl=")
                                      if !@m_showurl_durl_array[1].nil?
                                          @m_showurl_durl = CGI.unescape(@m_showurl_durl_array[1].to_s)
                                      end 
                                  end
                                  
                                  @adtype = ""
                                  
                                  @name = adgroup_name_hash["adgroup_id"+ad_d['cpc_grp_id'].to_s+"adgroup_name"].to_s
                                  @max_cpc = adgroup_price_hash["adgroup_id"+ad_d['cpc_grp_id'].to_s+"price"].to_f
                                  
                                  if @avg_pos.to_f > 0
                                      @avg_pos = @avg_pos.to_f / @impression.to_f
                                  end
                                  
                                  if @impression.to_f > 0
                                      @click_rate = (@click.to_f / @impression.to_f) * 100
                                  end
                                   
                                  if @click.to_f > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end 
                                  
                                  
                                  
                                  @data_conversion = conversion_hash["ad_id"+ad_d['cpc_idea_id'].to_s]
                                  
                                  if @data_conversion.to_i > 0
                                  
                                      if @click.to_f > 0 
                                        @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                                      end
                                      if @total_cost > 0
                                        @cpa = @total_cost.to_f / @data_conversion.to_f
                                      end
                                  
                                  end
                                  
                                  if @total_cost.to_f > 0
                                      @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+ad_d["cpc_grp_id"].to_s+"/ads"
                                                            
                                  if @csv.to_i == 1
                                      # csv_array << [ad_d["cpc_idea_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@max_cpc.to_f,@cpc.to_f,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                                      csv_array << [ad_d["cpc_idea_id"].to_i,@status.to_s,@name.to_s,ad_d["cpc_grp_id"].to_i,@campaign_title.to_s,@campaign_id.to_i,@campaign_type.to_s,@network_id.to_i,@network_name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl_durl.to_s,@visiturl_durl.to_s,@m_showurl_durl.to_s,@m_visiturl_durl.to_s,@adtype.to_s,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                                  else
                                      # data_array << [ad_d["cpc_idea_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@max_cpc.to_f,@cpc.to_f,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                                      data_array << [ad_d["cpc_idea_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['cpc_idea_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0,@link]
                                  end 
                    end
              end
      end
      
      
      
      if @campaign_type.to_s == "threesixty"
              
              @campaign = @db["all_campaign"].find('campaign_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
                
              arr = []  
              adg_arr = []
              
              @adgroup_title = ""
                
              db_name = "ad_360_"+@network_id.to_s  
              adgroup_db_name = "adgroup_360_"+@network_id.to_s
              
              if @adgroup_id.to_i > 0
                  @ad_count = @db[db_name].find('campaign_id' => @campaign_id.to_i,'adgroup_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup = @db[adgroup_db_name].find('adgroup_id' => @adgroup_id.to_i)
                  @db.close
                  
                  @adgroup.each do |adgroup|
                    @adgroup_title = adgroup["adgroup_name"]
                  end
              else
                  @ad_count = @db[db_name].find('campaign_id' => @campaign_id.to_i)
                  @db.close
              end
              
              if @ad_count.count.to_i >= 80000 && @filter_object.nil? && @csv.to_i == 0
                  data = {:recordsTotal => 0, :recordsFiltered => 0, :data => {}, :recordsTotal => 0, :recordsFiltered => 0, :data => [],:message => "Your Ad has more than 80000 record, try use the Advanced Filter or view this under specific Ad group.", :status => "false"}
                  return render :json => data, :status => :ok  
              end
              
              @ad_count.each do |ad_count|
                  arr << ad_count["ad_id"]  
                  adg_arr << ad_count["adgroup_id"]
              end
              
              threesixty_report_hash = {}
              @report_ad_360 = @db3[:report_ad_360].find('ad_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'views' => { "$gt" => 0})
              @db3.close
              
              if @report_ad_360.count.to_i > 0
                  @report_ad_360.each do |report_ad_360|
                    
                      if threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"views"]
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"views"] += report_ad_360['views'].to_i
                      else
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"views"] = report_ad_360['views'].to_i
                      end
                      
                      
                      if threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"clicks"]
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"clicks"] += report_ad_360['clicks'].to_i
                      else
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"clicks"] = report_ad_360['clicks'].to_i
                      end
                      
                      if threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"total_cost"]
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"total_cost"] += report_ad_360['total_cost'].to_f
                      else
                          threesixty_report_hash["ad_id"+report_ad_360['ad_id'].to_s+"total_cost"] = report_ad_360['total_cost'].to_f
                      end
                      
                  end
              end
              
              
      
              conversion_hash = {}
              conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
              @end_date = @end_date.to_date - 1.days
              conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
              
              
              
              @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'ad_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "360" } },
                               { '$group' => { '_id' => '$ad_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
              @db2.close
              
              
              if @all_conversion.count.to_i > 0 
                  @all_conversion.each do |all_conversion_arr|
                      conversion_hash["ad_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                      conversion_hash["ad_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                  end
              end
              
              
              
              
              # @all_conversion = @db2[:conversion].find('network_type' => "360",'ad_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
              # @db2.close 
#               
              # if @all_conversion.count.to_i > 0 
                  # @all_conversion.each do |all_conversion_arr|
#                       
                      # if conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s]
                          # conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s] += 1
                      # else
                          # conversion_hash["ad_id"+all_conversion_arr['ad_id'].to_s] = 1
                      # end
                  # end
              # end
              
              adgroup_name_hash = {}
              adgroup_price_hash = {}
              
              db_name = "adgroup_360_"+@network_id.to_s
              @adgroup_360 = @db[db_name].find('adgroup_id' => { "$in" => adg_arr})
              @db.close
                           
              if @adgroup_360.count.to_i != 0
                  @adgroup_360.each do |adgroup|
                      # @name = adgroup["adgroup_name"]
                      # @max_cpc = adgroup["price"]
                      
                      adgroup_name_hash["adgroup_id"+adgroup['adgroup_id'].to_s+"adgroup_name"] = adgroup["adgroup_name"]
                      adgroup_price_hash["adgroup_id"+adgroup['adgroup_id'].to_s+"price"] = adgroup["price"]
                  end
              end
              
              
      
              if @ad_count.count.to_i > 0
                    @ad_count.each do |ad_d|
                          @status = "Active"
                                  
                          if ad_d["status"].to_s == "暂停"
                              @status = "Inactive"  
                          end
                          
                          @impression = 0
                          @total_cost = 0
                          @click = 0
                          @click_rate = 0
                          @cpc = 0
                          @max_cpc = 0
                          @conv_rate = 0
                          @cpa = 0
                          
                          # ad doesnt have avg pos
                          @avg_pos = 0
                          # ad doesnt have avg pos
                           
                          if threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"views"]
                              @impression = threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"views"]
                          else
                              @impression = 0
                          end
                          
                          if threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"clicks"]
                              @click = threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"clicks"]
                          else
                              @click = 0
                          end
                          
                          if threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"total_cost"]
                              @total_cost = threesixty_report_hash["ad_id"+ad_d['ad_id'].to_s+"total_cost"]
                          else
                              @total_cost = 0
                          end
                          
                          @title = ad_d["title"]
                          @desc1 = ad_d["description"]
                          @desc2 = ""
                                                    
                          @visiturl = ad_d["visit_url"]
                          @showurl = ad_d["show_url"]
                          @m_visiturl = ad_d["mobile_visit_url"]
                          @m_showurl = ad_d["mobile_show_url"]
                          
                          @visiturl_durl = @visiturl
                          @showurl_durl = @showurl
                          @m_visiturl_durl = @m_visiturl
                          @m_showurl_durl = @m_showurl
                          
                          if @visiturl.to_s != "" && @visiturl.include?(".adeqo.")
                              @visit_url_durl_array = @visiturl.to_s.split("durl=")
                              if !@visit_url_durl_array[1].nil?
                                  @visiturl_durl = CGI.unescape(@visit_url_durl_array[1].to_s)
                              end 
                          end
                          
                          if @showurl.to_s != "" && @showurl.include?(".adeqo.")
                              @showurl_durl_array = @showurl.to_s.split("durl=")
                              if !@showurl_durl_array[1].nil?
                                  @showurl_durl = CGI.unescape(@showurl_durl_array[1].to_s)
                              end 
                          end
                          
                          if @m_visiturl.to_s != "" && @m_visiturl.include?(".adeqo.")
                              @m_visiturl_durl_array = @m_visiturl.to_s.split("durl=")
                              if !@m_visiturl_durl_array[1].nil?
                                  @m_visiturl_durl = CGI.unescape(@m_visiturl_durl_array[1].to_s)
                              end 
                          end
                          
                          if @m_showurl.to_s != "" && @m_showurl.include?(".adeqo.")
                              @m_showurl_durl_array = @m_showurl.to_s.split("durl=")
                              if !@m_showurl_durl_array[1].nil?
                                  @m_showurl_durl = CGI.unescape(@m_showurl_durl_array[1].to_s)
                              end 
                          end
                          
                          @adtype = ""
                                                   
                          
                          @name = adgroup_name_hash["adgroup_id"+ad_d['adgroup_id'].to_s+"adgroup_name"].to_s
                          @max_cpc = adgroup_price_hash["adgroup_id"+ad_d['adgroup_id'].to_s+"price"].to_f
                          
                          @data_conversion = conversion_hash["ad_id"+ad_d['ad_id'].to_s]
                                  
                          if @data_conversion.to_i > 0
                              if @click.to_f > 0 
                                  @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                              end
                              
                              if @total_cost.to_f > 0
                                  @cpa = @total_cost.to_f / @data_conversion.to_f
                              end
                          end
                          
                          if @total_cost.to_f > 0
                              @cpc = @total_cost.to_f / @click.to_f
                          end
                          
                          if @impression.to_f > 0
                              @click_rate = (@click.to_f / @impression.to_f) * 100
                          end
                          
                          @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+ad_d["adgroup_id"].to_s+"/ads"
                                  
                          if @csv.to_i == 1
                              # csv_array << [ad_d["ad_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@max_cpc.to_f,@cpc.to_f,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['ad_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                              csv_array << [ad_d["ad_id"].to_i,@status.to_s,@name.to_s,ad_d["adgroup_id"].to_i,@campaign_title.to_s,@campaign_id.to_i,@campaign_type.to_s,@network_id.to_i,@network_name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl_durl.to_s,@visiturl_durl.to_s,@m_showurl_durl.to_s,@m_visiturl_durl.to_s,@adtype.to_s,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['ad_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                          else
                              # data_array << [ad_d["ad_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@max_cpc.to_f,@cpc.to_f,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['ad_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                              data_array << [ad_d["ad_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@showurl.to_s,@visiturl.to_s,@m_showurl.to_s,@m_visiturl.to_s,@adtype.to_s,@impression.to_i,@click.to_i,@click_rate.to_f,@total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,0,conversion_hash["ad_id"+ad_d['ad_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0,@link]
                          end
                          
                    end
              end
      end
      
      
      
      
      
      if @csv.to_i == 1
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            if !@filter_object.nil?
                csv_array = filter_object_ad(@filter_object, csv_array)
            end
            
            if @export_csv_start_date == @export_csv_end_date
                if @adgroup_title.to_s == ""
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-ads_(" + @export_csv_start_date +")"
                else
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_ads-under_"+@adgroup_title.to_s+"(" + @export_csv_start_date +")"
                end
            else
                if @adgroup_title.to_s == ""
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-ads_(" + @export_csv_start_date + "-" + @export_csv_end_date +")"
                else
                    @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_ads-under_"+@adgroup_title.to_s+"(" + @export_csv_start_date + "-" + @export_csv_end_date +")"
                end
            end
            
                        
            head = ["\xEF\xBB\xBFAd ID","\xEF\xBB\xBFStatus","\xEF\xBB\xBFAd Group Name","\xEF\xBB\xBFAd Group ID","\xEF\xBB\xBFCampaign Name","\xEF\xBB\xBFCampaign ID","\xEF\xBB\xBFChannel Type","\xEF\xBB\xBFChannel ID","\xEF\xBB\xBFChannel Name","\xEF\xBB\xBFHeadline","\xEF\xBB\xBFDescription Line1","\xEF\xBB\xBFDescription Line2","Display Url","Final Url","Mobile Display Url","Mobile Final Url","Ad Type","Impr.","Clicks","CTR","Cost","Avg. CPC","Conversions","Conv. Rate","CPA","CPM","Revenue","Profit","Avg.pos","RPA","ROAS"]
            
            
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
            if !@filter_object.nil?
                data_array = filter_object_ad(@filter_object, data_array)
            end
            
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                # 1: "status" 
                # 3: ad group name
                # 4: headline/title
                # 5: desc line 1
                # 6: desc line 2
                # 7: display url
                # 8: final url
                # 9: ad type
                # 10: default max cpc
                # 11: avg cpc
                # 12: impressions
                # 13: clicks
                # 14: ctr
                # 15: cost
                # 16: conversions
                # 17: conv rate
                # 18: cpa
                # 19: cpm
                # 18: revenue
                
                if @sort_method.to_s == "asc"
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                else
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
            
            
            data = {:recordsTotal => data_array.count.to_i, :recordsFiltered => data_array.count.to_i, :data => data_array.drop(@skip_data.to_i).first(@length.to_i), :status => "true"}
            return render :json => data, :status => :ok
      end
      
      rescue Exception
          data = {:message => "Our System is updating, please come back later.", :status => "false"}
          return render :json => data, :status => :ok
      end
  end
  
  
  
  def getcampaignadgroup
    
      
      begin
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @campaign_type = params[:campaign_type]
      @campaign_id = params[:campaign_id]
      @network_id = params[:network_id]
      
      @skip_data = params[:start]
      @length = params[:length]
      session[:length] = params[:length]
      
      @order = params[:order]
      
      @filter_object = params[:filter_object]
      @csv = params[:csv]
      
      @account_array = params[:account_array]
      
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
        
      if @campaign_id.nil? || @campaign_type.nil?
          data = {:message => "Miss Campaign ID/Type.", :status => "false"}
          return render :json => data, :status => :ok
      end
        
      
      if @length.nil?
          @length = 5
      end
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
      
      csv_array = []
      data_array = []
      
      @network = @db["network"].find('id' => @network_id.to_i).limit(1)
      @db.close
      
      @network.each do |network_d|
        @network_name = network_d["name"]
      end
              
      
      if @campaign_type.to_s == "sogou"
              
              @campaign = @db["all_campaign"].find('cpc_plan_id' => @campaign_id.to_i).limit(1)
              @db.close
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
              
              arr = []
              
              db_name = "adgroup_sogou_"+@network_id.to_s
              query_hash = {}
              query_hash["cpc_plan_id"] = @campaign_id.to_i
              
              if !@filter_object.nil?
                  filter = @filter_object
                  
                  filter.each do |filter_object|
                      if filter_object[1]['name'].downcase.to_s == "status"
                        
                          if filter_object[1]['value'].downcase == "active"
                              @status_array = [21]
                              query_hash["status"] = { '$in' => @status_array }
                                                            
                          else
                              @status_array = [22,23]
                              query_hash["status"] = { '$in' => @status_array }
                          end
                          
                      elsif filter_object[1]['name'].downcase.to_s == "adgroup_name"
                        
                          if filter_object[1]['rule'].to_s == "**"
                              query_hash["name"] = {'$regex' => filter_object[1]['value'], '$options' => 'i'}
                          end
                          
                          if filter_object[1]['rule'].to_s == "!**"
                              query_hash["name"] = {'$regex' => '^((?!'+filter_object[1]['value']+').)*$', '$options' => 'i'}  
                          end
                          
                          if filter_object[1]['rule'].to_s == "="
                              query_hash["name"] = {'$regex' => '^'+filter_object[1]['value']+'$', '$options' => 'i'}  
                          end
                          
                          if filter_object[1]['rule'].to_s == "*="
                              query_hash["name"] = {'$regex' => '^'+filter_object[1]['value'], '$options' => 'i'}  
                          end
                                            
                      end
                  end
              end
              
              
              @adgroup_count = @db[db_name].find(query_hash)
              @db.close
              
              @adgroup_count.each do |adgroup_count_d|
                  arr << adgroup_count_d["cpc_grp_id"]  
              end
              
              sogou_report_hash = {}
              @sogou_report_adgroup = @db3[:sogou_report_adgroup].find('cpc_grp_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
              @db3.close 

              
              if @sogou_report_adgroup.count.to_i > 0
                  @sogou_report_adgroup.each do |sogou_report_adgroup|
                    
                      if sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"display"]
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"display"] += sogou_report_adgroup['display'].to_i
                      else
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"display"] = sogou_report_adgroup['display'].to_i
                      end
                      
                      if sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"clicks"]
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"clicks"] += sogou_report_adgroup['clicks'].to_i
                      else
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"clicks"] = sogou_report_adgroup['clicks'].to_i
                      end
                      
                      if sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"total_cost"]
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"total_cost"] += sogou_report_adgroup['total_cost'].to_f
                      else
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"total_cost"] = sogou_report_adgroup['total_cost'].to_f
                      end
                      
                      
                      if sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"avg_position"]
                        
                          if sogou_report_adgroup['display'].to_f > 0 && sogou_report_adgroup['avg_position'].to_f > 0
                              avg_pos = sogou_report_adgroup["avg_position"].to_f * sogou_report_adgroup["display"].to_f 
                              sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"avg_position"] += avg_pos.to_f
                          end
                      else
                          sogou_report_hash["adgroup_id"+sogou_report_adgroup['cpc_grp_id'].to_s+"avg_position"] = sogou_report_adgroup['avg_position'].to_f * sogou_report_adgroup['display'].to_i
                      end
                      
                  end
              end
              
              
              conversion_hash = {}
              conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
              @end_date = @end_date.to_date - 1.days
              conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
              
              
              @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'adgroup_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "sogou" } },
                               { '$group' => { '_id' => '$adgroup_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
              @db2.close
              
              
              if @all_conversion.count.to_i > 0 
                  @all_conversion.each do |all_conversion_arr|
                      conversion_hash["adgroup_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                      conversion_hash["adgroup_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                  end
              end
              
              
              
              # @all_conversion = @db2[:conversion].find('network_type' => "sogou",'adgroup_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
              # @db2.close
#               
#               
              # if @all_conversion.count.to_i > 0 
                  # @all_conversion.each do |all_conversion_arr|
#                       
                      # if conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s]
                          # conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s] += 1
                      # else
                          # conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s] = 1
                      # end
                  # end
              # end
                                  
              
      
              if @adgroup_count.count.to_i >0
                    @adgroup_count.each do |adgroup_d|
                      
                                  @status = "Active"
                                  @name = adgroup_d["name"]
                                  if adgroup_d["status"].to_i == 22
                                      @status = "Inactive"  
                                  end
                                  if adgroup_d["status"].to_i == 23
                                      @status = "Campaign Inactive"
                                  end
                                   
                                  @impression = 0
                                  @total_cost = 0
                                  @click = 0
                                  @click_rate = 0
                                  @cpc = 0
                                  @max_cpc = 0
                                  @avg_pos = 0
                                  @conv_rate = 0
                                  @cpa = 0 
                                   
                                  if sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"display"]
                                      @impression = sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"display"]
                                  else
                                      @impression = 0
                                  end
                                  
                                  if sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"clicks"]
                                      @click = sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"clicks"]
                                  else
                                      @click = 0
                                  end
                                  
                                  if sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"total_cost"]
                                      @total_cost = sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"total_cost"]
                                  else
                                      @total_cost = 0
                                  end
                                  
                                  
                                  if sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"avg_position"]
                                      @avg_pos = sogou_report_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"avg_position"]
                                  else
                                      @avg_pos = 0
                                  end 
                                  
                                  if @avg_pos.to_f > 0 && @impression.to_f > 0
                                    @avg_pos = @avg_pos.to_f / @impression.to_f
                                  end
                                  
                                  if @impression.to_f > 0
                                    @click_rate = (@click.to_f / @impression.to_f) * 100
                                  end 
                                  
                                  if @click.to_f > 0
                                    @cpc = @total_cost.to_f / @click.to_f
                                  end
                                  
                                  @max_cpc = adgroup_d['max_price']
                                  
                                  
                                  @data_conversion = conversion_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s]
                                  
                                  if @data_conversion.to_i > 0
                                      if @click.to_f > 0
                                          @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                                      end
                                      
                                      if @total_cost.to_f > 0
                                          @cpa = @total_cost.to_f / @data_conversion.to_f
                                      end
                                  end
                                  
                                  @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+adgroup_d["cpc_grp_id"].to_s+"/keyword"
                                  
                                  if @csv.to_i == 1
                                      csv_array << [adgroup_d["cpc_grp_id"].to_i, @status.to_s, @name.to_s,@campaign_id.to_i,@campaign_title.to_s,@campaign_type.to_s,@network_id.to_i,@network_name.to_s, @max_cpc.to_f, @impression.to_i ,@click.to_i, @click_rate, @total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                                  else
                                      data_array << [adgroup_d["cpc_grp_id"].to_i, @status.to_s, @name.to_s, @max_cpc.to_f, @impression.to_i ,@click.to_i, @click_rate, @total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["adgroup_id"+adgroup_d['cpc_grp_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0,@link]
                                  end
                    end 
              end
              
      end
      
      if @campaign_type.to_s == "threesixty"
            
            @campaign = @db["all_campaign"].find('campaign_id' => @campaign_id.to_i).limit(1)
            @db.close
            
            @campaign.each do |campaign|
              @campaign_title = campaign["campaign_name"]
            end
            
            arr = []
            
            db_name = "adgroup_360_"+@network_id.to_s
            
            
            query_hash = {}
            query_hash["campaign_id"] = @campaign_id.to_i
            
            if !@filter_object.nil?
                filter = @filter_object
                
                filter.each do |filter_object|
                    if filter_object[1]['name'].downcase.to_s == "status"
                      
                        if filter_object[1]['value'].downcase == "active"
                            @status_array = ["启用"]
                            query_hash["status"] = { '$in' => @status_array }
                                                          
                        else
                            @status_array = ["暂停"]
                            query_hash["status"] = { '$in' => @status_array }
                        end
                        
                    elsif filter_object[1]['name'].downcase.to_s == "adgroup_name"
                      
                        if filter_object[1]['rule'].to_s == "**"
                            query_hash["adgroup_name"] = {'$regex' => filter_object[1]['value'], '$options' => 'i'}
                        end
                        
                        if filter_object[1]['rule'].to_s == "!**"
                            query_hash["adgroup_name"] = {'$regex' => '^((?!'+filter_object[1]['value']+').)*$', '$options' => 'i'}  
                        end
                        
                        if filter_object[1]['rule'].to_s == "="
                            query_hash["adgroup_name"] = {'$regex' => '^'+filter_object[1]['value']+'$', '$options' => 'i'}  
                        end
                        
                        if filter_object[1]['rule'].to_s == "*="
                            query_hash["adgroup_name"] = {'$regex' => '^'+filter_object[1]['value'], '$options' => 'i'}  
                        end
                                          
                    end
                end
            end
            
            
            @adgroup_count = @db[db_name].find(query_hash)
            @db.close
            
            
            @adgroup_count.each do |adgroup_count_d|
                arr << adgroup_count_d["adgroup_id"]  
            end  
            
            threesixty_report_hash = {}
            @report_adgroup_360 = @db3[:report_adgroup_360].find('cpc_grp_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
            @db3.close
            
            if @report_adgroup_360.count.to_i > 0
                @report_adgroup_360.each do |report_adgroup_360|
                
                    if threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"display"]
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"display"] += report_adgroup_360['display'].to_i
                    else
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"display"] = report_adgroup_360['display'].to_i
                    end
                    
                    if threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"clicks"]
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"clicks"] += report_adgroup_360['clicks'].to_i
                    else
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"clicks"] = report_adgroup_360['clicks'].to_i
                    end
                    
                    if threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"total_cost"]
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"total_cost"] += report_adgroup_360['total_cost'].to_f
                    else
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"total_cost"] = report_adgroup_360['total_cost'].to_f
                    end
                    
                    if threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"avg_position"]
                      
                        if report_adgroup_360['display'].to_f > 0 && report_adgroup_360['avg_position'].to_f > 0
                            avg_pos = report_adgroup_360["avg_position"].to_f * report_adgroup_360["display"].to_f
                            threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"avg_position"] += avg_pos.to_f
                        end
                        
                    else
                        threesixty_report_hash["adgroup_id"+report_adgroup_360['cpc_grp_id'].to_s+"avg_position"] = report_adgroup_360["avg_position"].to_f * report_adgroup_360["display"].to_f
                    end
                
                end
            end
            
            
            conversion_hash = {}
            conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
            @end_date = @end_date.to_date - 1.days
            conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"
            
            
            
            @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'adgroup_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => "360" } },
                               { '$group' => { '_id' => '$adgroup_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => "$revenue" } } }
                                  ])
            @db2.close
            
            
            if @all_conversion.count.to_i > 0 
                @all_conversion.each do |all_conversion_arr|
                    conversion_hash["adgroup_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
                    conversion_hash["adgroup_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
                end
            end
          
              
            # @all_conversion = @db2[:conversion].find('network_type' => "360",'adgroup_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } )
            # @db2.close 
#             
            # if @all_conversion.count.to_i > 0 
                # @all_conversion.each do |all_conversion_arr|
#                     
                    # if conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s]
                        # conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s] += 1
                    # else
                        # conversion_hash["adgroup_id"+all_conversion_arr['adgroup_id'].to_s] = 1
                    # end
                # end
            # end
            
            
          
            if @adgroup_count.count.to_i >0
                    @adgroup_count.each do |adgroup_d|
                        @status = "Active"
                        @name = adgroup_d["adgroup_name"]
                        
                        if adgroup_d["status"].to_s.include?("暂停") || adgroup_d["sys_status"].to_s.include?("暂停")
                            @status = "Inactive"
                        end
                                   
                        @impression = 0
                        @total_cost = 0
                        @click = 0
                        @click_rate = 0
                        @cpc = 0
                        @max_cpc = 0
                        @avg_pos = 0
                        @conv_rate = 0
                        @cpa = 0
                        
                        
                        if threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"display"]
                            @impression = threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"display"]
                        else
                            @impression = 0
                        end
                        
                        if threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"clicks"]
                            @click = threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"clicks"]
                        else
                            @click = 0
                        end
                        
                        if threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"total_cost"]
                            @total_cost = threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"total_cost"]
                        else
                            @total_cost = 0
                        end
                        
                        if threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"avg_position"]
                            @avg_pos = threesixty_report_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"avg_position"]
                        else
                            @avg_pos = 0
                        end
                        
                        if @avg_pos.to_f > 0 && @impression.to_f > 0
                          @avg_pos = @avg_pos.to_f / @impression.to_f
                        end
                                  
                        if @impression.to_f > 0
                          @click_rate = (@click.to_f / @impression.to_f) * 100
                        end
                        
                        if @click.to_f > 0
                          @cpc = @total_cost.to_f / @click.to_f
                        end
                        
                        if @cpc.nil?
                          @cpc = 0
                        end
                        
                        @max_cpc = adgroup_d["price"]
                        
                        @data_conversion = conversion_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s]
                         
                        if @data_conversion.to_i > 0
                            if @click.to_i > 0
                                @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                            end
                             
                            if @total_cost.to_i > 0
                                @cpa = @total_cost.to_f / @data_conversion.to_f
                            end
                        end
                        
                        @link = "/campaigns/"+@campaign_id.to_s+"/"+@campaign_type.to_s+"/"+@network_id.to_s+"/adgroup/"+adgroup_d["adgroup_id"].to_s+"/keyword"
                        
                        if @csv.to_i == 1
                            csv_array << [adgroup_d["adgroup_id"].to_i, @status.to_s, @name.to_s,@campaign_id.to_i,@campaign_title.to_s,@campaign_type.to_s,@network_id.to_s,@network_name.to_s, @max_cpc.to_f, @impression.to_i ,@click.to_i, @click_rate, @total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0]
                        else
                            data_array << [adgroup_d["adgroup_id"].to_i, @status.to_s, @name.to_s, @max_cpc.to_f, @impression.to_i ,@click.to_i, @click_rate, @total_cost.to_f,@cpc.to_f,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["adgroup_id"+adgroup_d['adgroup_id'].to_s+"revenue"].to_f,0,@avg_pos.to_f,0,0,@link]
                        end
                        
                    end
            end
      end
      
      
      
      if @csv.to_i == 1
        
          @user_company.each do |doc|
            @user_company_name = doc["name"]
          end
          
          if !@filter_object.nil?
              csv_array = filter_object_adgroup(@filter_object, csv_array)
          end
          
          if @export_csv_start_date == @export_csv_end_date
              @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-adgroups_(" + @export_csv_start_date + ")"
          else
              @filename = @user_company_name.to_s.downcase + "_" + @campaign_title.to_s + "_all-adgroups_(" +@export_csv_start_date+"-"+@export_csv_end_date+")"
          end 
          
          
          head = ["\xEF\xBB\xBFAd Group ID","\xEF\xBB\xBFStatus","\xEF\xBB\xBFAd Group Name","\xEF\xBB\xBFCampaign ID","\xEF\xBB\xBFCampaign Name","\xEF\xBB\xBFChannel Type","\xEF\xBB\xBFChannel ID","\xEF\xBB\xBFChannel Name","\xEF\xBB\xBFDefault Max. CPC","Impr.","Clicks","CTR","Cost","Avg.CPC","Conversions","Conv. Rate","CPA","Revenue","Profit","Avg.pos","RPA","ROAS"]
          
          # csv(@filename,head,csv_array)
          excel(@filename,head,csv_array)
          
      else
      
          if !@filter_object.nil?
              data_array = filter_object_adgroup(@filter_object, data_array)
          end
          
          
          if !@order.nil? 
              @sort_column = @order["0"]["column"]
              @sort_method = @order["0"]["dir"]
              
              # 1: "status" 
              # 3: ad group name
              # 4: default max cpc
              # 5: impressions
              # 6: clicks
              # 7: ctr
              # 8: cost
              # 9: avg cpc
              # 10: conversions
              # 11: conv rate
              # 12: cpa
              
              if @sort_method.to_s == "asc"
                  data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
              else
                  data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
              end
          end
          
          data = {:recordsTotal => data_array.count.to_i, :recordsFiltered => data_array.count.to_i, :data => data_array.drop(@skip_data.to_i).first(@length.to_i)}
          return render :json => data, :status => :ok
      end
      
      rescue Exception
          data = {:message => "Our System is updating, please try again later.", :status => "false"}
          return render :json => data, :status => :ok
      end
  end
  
  
  def campaignkeyword
      campaignoverview
      @adgroup_id = params[:adgroupid]
  end
  
  def campaignads
      campaignoverview
      @adgroup_id = params[:adgroupid]
  end
  
  def campaignadgroup
      campaignoverview
  end


  
  def campaignsetting
      campaignoverview
      
      @network = @db[:network].find('id' => @network_id.to_i)
      @db.close
      
      if @network.count.to_i != 1
          return redirect_to "/campaigns"
      end 
      
      @network.each do |network|
  
        if network['type'].to_s == "sogou"
            @username = network["username"]
            @password = network["password"]
            @api_token = network["api_token"]
        end
        
        
        if network['type'].to_s == "360"
            
        end
      end
      
  end
  
  
  def campaignoverview
      @id = params[:id]
      @type = params[:type]
      @network_id = params[:networkid]
      @network_name = ""
      
          
      if @type.nil? || @id.nil?
        return redirect_to "/campaigns"
      end
      
      @network = @db["network"].find('id' => @network_id.to_i)
      @db.close
      
      if @network.count.to_i > 0
          @network.each do |network_d|
              @network_name = network_d["name"]
          end
      end
    
      @campaign = "" 
      
      if @type == "sogou"
          # db_name = "campaign_sogou_"+@network_id.to_s
          # @sogou_campaign = @db[db_name].find('cpc_plan_id' => @id.to_i)
          
          
          @sogou_campaign = @db["all_campaign"].find('cpc_plan_id' => @id.to_i, 'network_type' => "sogou").limit(1)
          @db.close
                    
          if @sogou_campaign.count.to_i > 0
              @campaign = @sogou_campaign
          else
              return redirect_to "/campaigns"
          end
          
          
      
      elsif @type == "threesixty"
          # db_name = "campaign_360_"+@network_id.to_s
          # @campaign_360 = @db[db_name].find('campaign_id' => @id.to_i)
          
          @campaign_360 = @db["all_campaign"].find('campaign_id' => @id.to_i, 'network_type' => "360").limit(1)
          @db.close
          
          if @campaign_360.count.to_i > 0
              @campaign = @campaign_360
          else
              return redirect_to "/campaigns"
          end
      end
      
      @db.close
      
      
      
      if @campaign == ""
          return redirect_to "/campaigns"
      end
  end
  
  
  def getcampaignoverview
    
      csv_array = []
      @campaignoverview = []
      @campaignoverview_count = 0
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @campaign_type = params[:campaign_type]
      @campaign_id = params[:campaign_id]
      @network_id = params[:network_id]
      
      @skip_data = params[:start]
      @length = params[:length]
      session[:length] = params[:length]
      
      @csv = params[:csv]
      @order = params[:order] 
      
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      if @campaign_id.nil? || @campaign_type.nil?
          data = {:message => "Your data is updating, please come back later.", :status => "false"}
          return render :json => data, :status => :ok
      end
      
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
      
      
      @skip_index = 0       
      @index = 0
      
      
      if @campaign_type.to_s == "sogou"
              
              
              @campaign = @db["all_campaign"].find('cpc_plan_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
              
              @sogou_report_account = @db3[:sogou_report_campaign].find('cpc_plan_id' => @campaign_id.to_i, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }).skip(@skip_data.to_i).limit(@length.to_i)
              @db3.close
              
              
              @sogou_report_account.each do |account|
                 
                  conversion_request_start_date = account['report_date'].to_s+" 00:00:00 CST"
                  conversion_request_end_date = account['report_date'].to_s+" 23:59:59 CST"
      
                  @conversion = @db2[:conversion].find('network_type' => "sogou",'campaign_id' => @campaign_id.to_i, 'date' => { '$gte' => conversion_request_start_date.to_s ,'$lte' => conversion_request_end_date.to_s } )
                  @db2.close
                  
                  @all_conversion = @db2[:conversion].find.aggregate([ 
                                                               { '$match' => { 'network_type' => "sogou",'campaign_id' => @campaign_id.to_i, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } } },
                                                               { '$group' => { '_id' => '$network_type', 'revenue' => { '$sum' => "$revenue" } } }
                                                            ])
                  @db2.close
                 
                  if @all_conversion.count.to_i > 0
                      @revenue = @all_conversion.first['revenue'].to_f
                  else
                      @revenue = 0  
                  end
                  
            
                  @conv_rate = (@conversion.count.to_f / account["clicks"].to_f) * 100
                  @cpa = 0
                  if account["total_cost"].to_f > 0 && @conversion.count.to_f > 0
                      @cpa = (account["total_cost"].to_f / @conversion.count.to_f)
                  end
                  
                  if @csv.to_i == 1
                      csv_array << [account['report_date'].to_s, account["display"].to_f, account["clicks"].to_i, account["total_cost"].to_i ,account["clicks_avg_price"].to_f, account["click_rate"].gsub('%','').to_f,@conversion.count.to_i,@conv_rate,@cpa,@revenue.to_f]
                  else
                      @campaignoverview << [account['report_date'].to_s, account["display"].to_f, account["clicks"].to_i, account["total_cost"].to_i ,account["clicks_avg_price"].to_f, account["click_rate"].gsub('%','').to_f,@conversion.count.to_i,@conv_rate,@cpa,@revenue.to_f]
                  end
                  
                  @skip_index = @skip_index + 1
                  @campaignoverview_count = @campaignoverview_count.to_i + 1 
                  
              end
          
      end
      
      
      if @campaign_type.to_s == "threesixty"
              
              
              @campaign = @db["all_campaign"].find('campaign_id' => @campaign_id.to_i).limit(1)
              @db.close
              
              @campaign.each do |campaign|
                @campaign_title = campaign["campaign_name"]
              end
              
              @report_campaign_360 = @db3[:report_campaign_360].find('cpc_plan_id' => @campaign_id.to_i, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }).skip(@skip_data.to_i).limit(@length.to_i)
              @db3.close
              
              
              @report_campaign_360.each do |account|
                  
                  conversion_request_start_date = account['report_date'].to_s+" 00:00:00 CST"
                  conversion_request_end_date = account['report_date'].to_s+" 23:59:59 CST"
                  
                  @conversion = @db2[:conversion].find('network_type' => "360",'campaign_id' => @campaign_id.to_i, 'date' => { '$gte' => conversion_request_start_date.to_s ,'$lte' => conversion_request_end_date.to_s } )
                  @db2.close
                  
                  @all_conversion = @db2[:conversion].find.aggregate([ 
                                                               { '$match' => { 'network_type' => "360",'campaign_id' => @campaign_id.to_i, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s } } },
                                                               { '$group' => { '_id' => '$network_type', 'revenue' => { '$sum' => "$revenue" } } }
                                                            ])
                  @db2.close
                  
                  if @all_conversion.count.to_i > 0
                      @revenue = @all_conversion.first['revenue'].to_f
                  else
                      @revenue = 0  
                  end
                  
                  @clicks_avg_price = account["total_cost"].to_f / account["clicks"].to_f
                  @click_rate = ( account["clicks"].to_f / account["display"].to_f ) * 100
                  
                  @conv_rate = (@conversion.count.to_f / account["clicks"].to_f) * 100
                  
                  @cpa = 0
                  if account["total_cost"].to_f > 0 && @conversion.count.to_f > 0
                      @cpa = (account["total_cost"].to_f / @conversion.count.to_f)
                  end
                  
                  if @csv.to_i == 1
                      csv_array << [account['report_date'].to_s, account["display"].to_f, account["clicks"].to_i, account["total_cost"].to_i ,@clicks_avg_price.to_f, @click_rate.to_f,@conversion.count.to_i,@conv_rate,@cpa,@revenue.to_f]
                  else
                      @campaignoverview << [account['report_date'].to_s, account["display"].to_f, account["clicks"].to_i, account["total_cost"].to_i ,@clicks_avg_price.to_f, @click_rate.to_f,@conversion.count.to_i,@conv_rate,@cpa,@revenue.to_f]
                  end
                  
                  @skip_index = @skip_index + 1
                  @campaignoverview_count = @campaignoverview_count.to_i + 1 
                  
              end
      end
      
      
      
      if @csv.to_i == 1
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            if @export_csv_start_date == @export_csv_end_date
                @filename = @user_company_name.to_s.downcase + "_campaign_" + @campaign_title.to_s + "_" + @export_csv_start_date
            else
                @filename = @user_company_name.to_s.downcase + "_campaign_" + @campaign_title.to_s + "_" + @export_csv_start_date + "-" +@export_csv_end_date
            end
                        
            head = ["Date", "Impr.", "Clicks", "Pub.Cost", "Avg.CPC", "CTR", "Conversion", "Conv.Rate", "Cost", "Revenue"]
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                # 1: "date" 
                # 3: impr
                # 4: click
                # 5: pub cost
                # 6: avg cpc
                # 7: ctr
                # 8: conversion
                # 9: conv rate
                # 10: cost
                # 11: revenue
                
                if @sort_method.to_s == "asc"
                    @campaignoverview = @campaignoverview.sort_by{|k|k[@sort_column.to_i]}
                else
                    @campaignoverview = @campaignoverview.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
            
            
            data = {:recordsTotal => @campaignoverview_count.to_i, :recordsFiltered => @campaignoverview_count.to_i, :data => @campaignoverview.drop(@skip_data.to_i).first(@length.to_i)}
            return render :json => data, :status => :ok
      end
  end
  
  
  
  def channelaccounts
    
  end
  
  
  def sync
    
      @id = params[:id]
      
      if !@id.nil?
          @network = @db["network"].find('id' => { "$in" => @id})
          
          if @network.count.to_i > 0
              @network.each do |network_d|
                  
                  if network_d['type'].to_s == "sogou"
                    
                      uri = URI('http://google.com')
                      req = Net::HTTP.get(uri)
                      
                  elsif network_d['type'].to_s == "360"
                    
                      uri = URI('http://hk.yahoo.com')
                      req = Net::HTTP.get(uri)
                      
                  end
                  
              end
          end
      end
       
      data = {:message => "Sync", :sad => @id, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  def getnetworkaccounts    
      
      # @logger.info "new Load Network getnetworkaccount "+ @now.to_s
      
      begin
      
      @draw = params[:draw]
      @length = params[:length]
      session[:length] = params[:length]
      
      @skip_data = params[:start]
      @channel_array = params[:channel_array]
      @filter_account_array = params[:account_array]
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      @order = params[:order]
      
      @filter_object = params[:filter_object]
      @csv = params[:csv]
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @current_user_network = @db[:network].find('company_id' => @user_company_id)
      @db.close
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
      
      
      if @channel_array.nil?
          @channel_array = []
      end
      
      if @draw.nil?
        @draw = 0
      end
      
      if @length.nil?
        @length = 5
      end
      
      @index = 0
      @network_index = 0
      
      
      @user_network_array = []
      
      if !@filter_account_array.nil?
          @filter_account_array.each do |filter_network|
              @user_network_array << filter_network.to_i
          end
      else
        
          @user_network = @db[:network_user].find('user' => session[:user_id].to_i)
          @db.close
        
          @user_network.each do |user_network|
              @user_network_array << user_network["network_id"]
          end
      end
      
      data_array = []
      data_array_count = 0
      csv_array = []
      
      # @all_campaign_count = @db["all_campaign"].find('network_id' => { "$in" => @user_network_array},'network_type' => { "$in" => @channel_array})
      
      @network = @db["network"].find('id' => { "$in" => @user_network_array},'type' => { "$in" => @channel_array})
      @db.close
      
               
      
      
      
      sogou_report_hash = {}
      if @channel_array.include?("sogou")
          @sogou_account_report = @db3[:sogou_report_account].find('network_id' => { "$in" => @user_network_array}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
          @db3.close
          
          if @sogou_account_report.count.to_i > 0 
              @sogou_account_report.each do |sogou_account_report_arr|
                  
                  if sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"display"]
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"display"] += sogou_account_report_arr['display'].to_i
                  else
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"display"] = sogou_account_report_arr['display'].to_i
                  end
                  
                  if sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"clicks"]
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"clicks"] += sogou_account_report_arr['clicks'].to_i
                  else
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"clicks"] = sogou_account_report_arr['clicks'].to_i
                  end
                  
                  if sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"total_cost"]
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"total_cost"] += sogou_account_report_arr['total_cost'].to_f
                  else
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"total_cost"] = sogou_account_report_arr['total_cost'].to_f
                  end
                  
                  if sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"avg_position"]
                    
                      if sogou_account_report_arr['display'].to_f > 0 && sogou_account_report_arr['avg_position'].to_f > 0
                          avg_pos = sogou_account_report_arr["avg_position"].to_f * sogou_account_report_arr["display"].to_f
                          sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"avg_position"] += avg_pos.to_f
                      end
                      
                  else
                      sogou_report_hash["network_id"+sogou_account_report_arr['network_id'].to_s+"avg_position"] = sogou_account_report_arr["avg_position"].to_f * sogou_account_report_arr["display"].to_f
                  end
              end
          end
      end
      
      
      threesixty_report_hash = {}
      if @channel_array.include?("360")
          @three_sixty_account_report = @db3[:report_account_360].find('network_id' => { "$in" => @user_network_array}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
          @db3.close
          
          if @three_sixty_account_report.count.to_i > 0 
              @three_sixty_account_report.each do |three_sixty_account_report_arr|
                  
                  if threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"display"]
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"display"] += three_sixty_account_report_arr['display'].to_i
                  else
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"display"] = three_sixty_account_report_arr['display'].to_i
                  end
                  
                  if threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"clicks"]
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"clicks"] += three_sixty_account_report_arr['clicks'].to_i
                  else
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"clicks"] = three_sixty_account_report_arr['clicks'].to_i
                  end
                  
                  if threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"total_cost"]
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"total_cost"] += three_sixty_account_report_arr['total_cost'].to_f
                  else
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"total_cost"] = three_sixty_account_report_arr['total_cost'].to_f
                  end
                  
                  if threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"avg_position"]
                      if three_sixty_account_report_arr['display'].to_f > 0 && three_sixty_account_report_arr['avg_position'].to_f
                          avg_pos = three_sixty_account_report_arr["avg_position"].to_f * three_sixty_account_report_arr["display"].to_f
                          threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"avg_position"] += avg_pos.to_f
                      end
                  else
                      threesixty_report_hash["network_id"+three_sixty_account_report_arr['network_id'].to_s+"avg_position"] = three_sixty_account_report_arr["avg_position"].to_f * three_sixty_account_report_arr["display"].to_f
                  end
              end
          end
      end
      
      
      
      conversion_hash = {}
      
      conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
      @end_date = @end_date.to_date - 1.days
      conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"        
      
      
      
      
      @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'network_id' => { "$in" => @user_network_array}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => { "$in" => @channel_array} } },
                               { '$group' => { '_id' => '$network_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => '$revenue' } } }
                          ])
      @db2.close
      
      
      if @all_conversion.count.to_i > 0 
          @all_conversion.each do |all_conversion_arr|
              conversion_hash["network_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
              conversion_hash["network_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
          end
      end
      
      # @all_conversion = @db2[:conversion].find.('campaign_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => { "$in" => @channel_array}).sort({ campaign_id: -1 })
      # if @all_conversion.count.to_i > 0 
          # @all_conversion.each do |all_conversion_arr|
#               
              # if conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s]
                  # conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s] += 1
              # else
                  # conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s] = 1
              # end
          # end
      # end
      
      
      network_hash = {}
      if @network.count.to_i > 0 
          @network.each do |network|
              
              @impression = 0
              @click = 0
              @total_cost = 0
              @avg_pos = 0
              @cpc = 0
              @ctr = 0
              @conv_rate = 0
              @cpa = 0
              
              @sync = 1
              if network["file_update_1"].to_i == 4 && network["file_update_2"].to_i == 4 && network["file_update_3"].to_i == 4 && network["file_update_4"].to_i == 4
                  @sync = 1
              else
                  @sync = 0
              end
                  
              if network["type"] == "sogou"
                
                  if sogou_report_hash["network_id"+network['id'].to_s+"display"]
                      @impression = sogou_report_hash["network_id"+network['id'].to_s+"display"]
                  else
                      @impression = 0
                  end
                  
                  if sogou_report_hash["network_id"+network['id'].to_s+"clicks"]
                      @click = sogou_report_hash["network_id"+network['id'].to_s+"clicks"]
                  else
                      @click = 0
                  end
                  
                  if sogou_report_hash["network_id"+network['id'].to_s+"total_cost"]
                      @total_cost = sogou_report_hash["network_id"+network['id'].to_s+"total_cost"]
                  else
                      @total_cost = 0
                  end
                  
                  if sogou_report_hash["network_id"+network['id'].to_s+"avg_position"]
                      @avg_pos = sogou_report_hash["network_id"+network['id'].to_s+"avg_position"]
                  else
                      @avg_pos = 0
                  end
                   
                  if @total_cost.to_f > 0 && @click.to_f > 0
                      @cpc = @total_cost.to_f/@click.to_f
                  end
                  if @click.to_f > 0 && @impression.to_f > 0
                      @ctr = (@click.to_f/@impression.to_f)*100
                  end
                   
                  if @avg_pos > 0 && @impression > 0
                      @avg_pos = @avg_pos.to_f / @impression.to_f
                  end
                   
                  @link = "/channel/"+network["id"].to_s+"/campaigns"
                  
                  @data_conversion = conversion_hash["network_id"+network["id"].to_s]
                  
                  if @data_conversion.to_i > 0
                      
                      if @click.to_i > 0
                          @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                      end
                      if @total_cost.to_i > 0
                          @cpa = @total_cost.to_f / @data_conversion.to_f
                      end
                  end
                  
                  if @csv.to_i == 1
                      csv_array << [network["id"],network["name"],"Sogou",@impression.to_i,@click.to_i,@total_cost.to_i,@ctr.to_i,@data_conversion.to_i,@conv_rate.to_f,"0"]
                  else
                      data_array << [network["id"],network["name"],"Sogou",@impression.to_i,@click.to_i,@total_cost.to_i,@ctr.to_i,@data_conversion.to_i,@conv_rate.to_f,"0",@link,@sync,network["last_update"]]
                  end
                
              end
              
              
              if network["type"] == "360"
                  
                  if threesixty_report_hash["network_id"+network['id'].to_s+"display"]
                      @impression = threesixty_report_hash["network_id"+network['id'].to_s+"display"]
                  else
                      @impression = 0
                  end
                  
                  if threesixty_report_hash["network_id"+network['id'].to_s+"clicks"]
                      @click = threesixty_report_hash["network_id"+network['id'].to_s+"clicks"]
                  else
                      @click = 0
                  end
                  
                  if threesixty_report_hash["network_id"+network['id'].to_s+"total_cost"]
                      @total_cost = threesixty_report_hash["network_id"+network['id'].to_s+"total_cost"]
                  else
                      @total_cost = 0
                  end
                  
                  if threesixty_report_hash["network_id"+network['id'].to_s+"avg_position"]
                      @avg_pos = threesixty_report_hash["network_id"+network['id'].to_s+"avg_position"]
                  else
                      @avg_pos = 0
                  end
                  
                  if @total_cost.to_f > 0 && @click.to_f > 0
                      @cpc = @total_cost.to_f/@click.to_f
                  end
                  if @click.to_f > 0 && @impression.to_f > 0
                      @ctr = (@click.to_f/@impression.to_f)*100
                  end
                   
                  if @avg_pos > 0 && @impression > 0
                      @avg_pos = @avg_pos.to_f / @impression.to_f
                  end
                  
                  @link = "/channel/"+network["id"].to_s+"/campaigns"
                  
                  @data_conversion = conversion_hash["network_id"+network["id"].to_s]
                  
                  if @data_conversion.to_i > 0
                      
                      if @click.to_i > 0
                          @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                      end
                      if @total_cost.to_i > 0
                          @cpa = @total_cost.to_f / @data_conversion.to_f
                      end  
                  end

                  
                  if @csv.to_i == 1
                      csv_array << [network["id"],network["name"],"360",@impression.to_i,@click.to_i,@total_cost.to_i,@ctr.to_i,@data_conversion.to_i,@conv_rate.to_f,"0"]
                  else
                      data_array << [network["id"],network["name"],"360",@impression.to_i,@click.to_i,@total_cost.to_i,@ctr.to_i,@data_conversion.to_i,@conv_rate.to_f,"0",@link,@sync,network["last_update"]]
                  end
                  
              end
              
              
          end
      end
      
      
      if @csv.to_i == 1
        
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            if @export_csv_start_date == @export_csv_end_date then
                @filename = @user_company_name.to_s.downcase + "_all_account_(" + @export_csv_start_date +")"
            else
                @filename = @user_company_name.to_s.downcase + "_all_account_(" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
            end 
            
            head = ["\xEF\xBB\xBFID","\xEF\xBB\xBFAccount","\xEF\xBB\xBFChannel", "\xEF\xBB\xBFImpression", "\xEF\xBB\xBFclick", "\xEF\xBB\xBFCost", "\xEF\xBB\xBFCTR", "Conversion", "Conversion Rate", "Revenue"]
            
            if !@filter_object.nil?
                csv_array = filter_object_network(@filter_object, csv_array)
            end
            
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
        
            if !@filter_object.nil?
                data_array = filter_object_network(@filter_object, data_array)
            end
            
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                # 1: "campaign" 
                # 3: channel
                # 4: account
                # 5: currency
                # 6: impression
                # 7: clicks
                # 8: cost
                # 9: cpc
                # 10: ctr
                # 11: conversion
                # 12: conv rate
                # 13: cpa
                # 14: revenue
                # 15: profit
                # 16: avg pos
                # 17: rpa
                # 18: roas
                
                if @sort_method.to_s == "asc"
                    # data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                    # data_array.sort_by{|k|k[@sort_column.to_i]}   2.6 min
                    
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                else
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
        
            
        
            data = {
              :draw => @draw,
              :recordsTotal => data_array.count.to_i,
              :recordsFiltered => data_array.count.to_i,
              :data => data_array.drop(@skip_data.to_i).first(@length.to_i),
              # :data => data_array,
              # :data => [],
              :status => "true"
            }
            
            return render :json => data, :status => :ok
      end  
      
      rescue Exception
          data = {:msg => "Our System is updating, please try again later.", :status => "false"}
          return render :json => data, :status => :ok
      end
  end
  
  
  
  
  
  
  def campaigns
      @id_pre_select = params[:id]
  end
  
  
  def getallleveldata
    
      # @logger.info "called getallleveldata "+ @now.to_s
      
      
      
      # @logger.info "called getallleveldata done"+ @now.to_s
  end
  
  
  def getcampaigns    
      
      # @logger.info "new Load Network getcampaign "+ @now.to_s
      
      begin
      
      @draw = params[:draw]
      @length = params[:length]
      session[:length] = params[:length]
      
      @skip_data = params[:start]
      @channel_array = params[:channel_array]
      @filter_account_array = params[:account_array]
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      @order = params[:order]
      
      @filter_object = params[:filter_object]
      @csv = params[:csv]
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = @today
          @end_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date + 1.days
          @end_date = @end_date.strftime("%Y-%m-%d")
      end
      
      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")
      else
          session[:start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date - 1.days
          @start_date = @start_date.strftime("%Y-%m-%d")
      end
      
      @current_user_network = @db[:network].find('company_id' => @user_company_id)
      @db.close
      
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")
      day_range = (@end_date.to_date - @start_date.to_date).to_i
      
      current_day = @today.strftime("%d")
      last_day = Date.today.end_of_month.strftime("%d")
      first_date_of_this_month = Date.today.at_beginning_of_month.strftime("%Y-%m-%d")
      
      
      if @channel_array.nil?
          @channel_array = []
      end
      
      if @draw.nil?
        @draw = 0
      end
      
      if @length.nil?
        @length = 5
      end
      
      @index = 0
      @network_index = 0
      
      
      @user_network_array = []
      
      if !@filter_account_array.nil?
          @filter_account_array.each do |filter_network|
              @user_network_array << filter_network.to_i
          end
      else
        
          @user_network = @db[:network_user].find('user' => session[:user_id].to_i)
          @db.close
        
          @user_network.each do |user_network|
              @user_network_array << user_network["network_id"]
          end
      end
      
      data_array = []
      data_array_count = 0
      csv_array = []
      
      # @all_campaign_count = @db["all_campaign"].find('network_id' => { "$in" => @user_network_array},'network_type' => { "$in" => @channel_array})
      # @db.close
      
      query_hash = {}
      query_hash["network_id"] = { '$in' => @user_network_array }
      query_hash["network_type"] = { '$in' => @channel_array }
      
      if !@filter_object.nil?
          filter = @filter_object
          
          filter.each do |filter_object|
              if filter_object[1]['name'].downcase.to_s == "status"
                
                  if filter_object[1]['value'].downcase == "active"
                      @status_array = ["启用",11]
                      query_hash["status"] = { '$in' => @status_array }
                                                    
                  else
                      @status_array = ["暂停",12]
                      query_hash["status"] = { '$in' => @status_array }
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "campaign_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      query_hash["campaign_name"] = {'$regex' => filter_object[1]['value'], '$options' => 'i'}
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      query_hash["campaign_name"] = {'$regex' => '^((?!'+filter_object[1]['value']+').)*$', '$options' => 'i'}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      query_hash["campaign_name"] = {'$regex' => '^'+filter_object[1]['value']+'$', '$options' => 'i'}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      query_hash["campaign_name"] = {'$regex' => '^'+filter_object[1]['value'], '$options' => 'i'}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "account_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      query_hash["account_name"] = {'$regex' => filter_object[1]['value'], '$options' => 'i'}
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      query_hash["account_name"] = {'$regex' => '^((?!'+filter_object[1]['value']+').)*$', '$options' => 'i'}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      query_hash["account_name"] = {'$regex' => '^'+filter_object[1]['value']+'$', '$options' => 'i'}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      query_hash["account_name"] = {'$regex' => '^'+filter_object[1]['value'], '$options' => 'i'}  
                  end
                                    
              end
          end
      end
      
      
      @all_campaign_count = @db["all_campaign"].find(query_hash)
      @db.close
      
      
      arr = []
      @all_campaign_count.each do |all_campaign_count_d|
          if all_campaign_count_d["network_type"] == "360"
              arr << all_campaign_count_d["campaign_id"]            
          end
          
          if all_campaign_count_d["network_type"] == "sogou"
              arr << all_campaign_count_d["cpc_plan_id"]  
          end
      end      
          
      @network = @db["network"].find('id' => { "$in" => @user_network_array})
      
      sogou_report_hash = {}
      if @channel_array.include?("sogou")
          @sogou_campaign_report = @db3[:sogou_report_campaign].find('cpc_plan_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
          @db3.close
          
          if @sogou_campaign_report.count.to_i > 0 
              @sogou_campaign_report.each do |sogou_campaign_report_arr|
                  
                  if sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"display"]
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"display"] += sogou_campaign_report_arr['display'].to_i
                  else
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"display"] = sogou_campaign_report_arr['display'].to_i
                  end
                  
                  if sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"clicks"]
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"clicks"] += sogou_campaign_report_arr['clicks'].to_i
                  else
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"clicks"] = sogou_campaign_report_arr['clicks'].to_i
                  end
                  
                  if sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"]
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"] += sogou_campaign_report_arr['total_cost'].to_f
                  else
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"] = sogou_campaign_report_arr['total_cost'].to_f
                  end
                  
                  if sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"]
                    
                      if sogou_campaign_report_arr['display'].to_f > 0 && sogou_campaign_report_arr['avg_position'].to_f > 0
                          avg_pos = sogou_campaign_report_arr["avg_position"].to_f * sogou_campaign_report_arr["display"].to_f
                          sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"] += avg_pos.to_f
                      end
                      
                  else
                      sogou_report_hash["campaign_id"+sogou_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"] = sogou_campaign_report_arr["avg_position"].to_f * sogou_campaign_report_arr["display"].to_f
                  end
              end
          end
      end
      
      
      threesixty_report_hash = {}
      if @channel_array.include?("360")
          @three_sixty_campaign_report = @db3[:report_campaign_360].find('cpc_plan_id' => { "$in" => arr}, 'report_date' => { '$gt' => @start_date.to_s, '$lt' => @end_date.to_s }, 'display' => { "$gt" => 0})
          @db3.close
          
          if @three_sixty_campaign_report.count.to_i > 0 
              @three_sixty_campaign_report.each do |three_sixty_campaign_report_arr|
                  
                  if threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"display"]
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"display"] += three_sixty_campaign_report_arr['display'].to_i
                  else
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"display"] = three_sixty_campaign_report_arr['display'].to_i
                  end
                  
                  if threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"clicks"]
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"clicks"] += three_sixty_campaign_report_arr['clicks'].to_i
                  else
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"clicks"] = three_sixty_campaign_report_arr['clicks'].to_i
                  end
                  
                  if threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"]
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"] += three_sixty_campaign_report_arr['total_cost'].to_f
                  else
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"total_cost"] = three_sixty_campaign_report_arr['total_cost'].to_f
                  end
                  
                  if threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"]
                      if three_sixty_campaign_report_arr['display'].to_f > 0 && three_sixty_campaign_report_arr['avg_position'].to_f
                          avg_pos = three_sixty_campaign_report_arr["avg_position"].to_f * three_sixty_campaign_report_arr["display"].to_f
                          threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"] += avg_pos.to_f
                      end
                  else
                      threesixty_report_hash["campaign_id"+three_sixty_campaign_report_arr['cpc_plan_id'].to_s+"avg_position"] = three_sixty_campaign_report_arr["avg_position"].to_f * three_sixty_campaign_report_arr["display"].to_f
                  end
              end
          end
      end
      
      
      
      conversion_hash = {}
      
      conversion_request_start_date = @start_date.to_s+" 00:00:00 CST"
      @end_date = @end_date.to_date - 1.days
      conversion_request_end_date = @end_date.to_s+" 23:59:59 CST"        
      
      
      
      
      
      @all_conversion = @db2[:conversion].find.aggregate([ 
                               { '$match' => { 'campaign_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => { "$in" => @channel_array} } },
                               { '$group' => { '_id' => '$campaign_id', 'count' => { '$sum' => 1 }, 'revenue' => { '$sum' => '$revenue' } } }
                          ])
      @db2.close
      
      
      if @all_conversion.count.to_i > 0 
          @all_conversion.each do |all_conversion_arr|
              conversion_hash["campaign_id"+all_conversion_arr['_id'].to_s] = all_conversion_arr['count'].to_i
              conversion_hash["campaign_id"+all_conversion_arr['_id'].to_s+"revenue"] = all_conversion_arr['revenue'].to_f
          end
      end
      
      # @all_conversion = @db2[:conversion].find.('campaign_id' => { "$in" => arr}, 'date' => { '$gt' => conversion_request_start_date.to_s, '$lt' => conversion_request_end_date.to_s },'network_type' => { "$in" => @channel_array}).sort({ campaign_id: -1 })
      # if @all_conversion.count.to_i > 0 
          # @all_conversion.each do |all_conversion_arr|
#               
              # if conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s]
                  # conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s] += 1
              # else
                  # conversion_hash["campaign_id"+all_conversion_arr['campaign_id'].to_s] = 1
              # end
          # end
      # end
      
      
      network_hash = {}
      if @network.count.to_i > 0 
          @network.each do |network|
              
              network_array = []
              
              network_array << network["name"]
              network_array << network["currency"]
              network_array << network["type"]
              
              network_hash["id"+network["id"].to_s] = network_array
          end
      end
      
       
      if @all_campaign_count.count.to_i > 0
          @all_campaign_count.each do |campaign|
              @status = "Active"
              @impression = 0
              @click = 0
              @total_cost = 0
              @avg_pos = 0
              @cpc = 0
              @ctr = 0
              @conv_rate = 0
              @cpa = 0
                
              if campaign["status"].to_s == "暂停" || campaign["status"].to_i == 12     
                  @status = "Inactive"
              end
               
              if campaign["network_type"] == "sogou"
                  
                  if sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"display"]
                      @impression = sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"display"]
                  else
                      @impression = 0
                  end
                  
                  if sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"clicks"]
                      @click = sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"clicks"]
                  else
                      @click = 0
                  end
                  
                  if sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"total_cost"]
                      @total_cost = sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"total_cost"]
                  else
                      @total_cost = 0
                  end
                  
                  if sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"avg_position"]
                      @avg_pos = sogou_report_hash["campaign_id"+campaign['cpc_plan_id'].to_s+"avg_position"]
                  else
                      @avg_pos = 0
                  end
#                   
                  if @total_cost.to_f > 0 && @click.to_f > 0
                      @cpc = @total_cost.to_f/@click.to_f
                  end
                  if @click.to_f > 0 && @impression.to_f > 0
                      @ctr = (@click.to_f/@impression.to_f)*100
                  end
                   
                  if @avg_pos > 0 && @impression > 0
                      @avg_pos = @avg_pos.to_f / @impression.to_f
                  end

                   
                  @link = "/campaigns/"+campaign["cpc_plan_id"].to_s+"/sogou/"+campaign["network_id"].to_s+"/adgroup"
                  @account_link = "/channel/"+campaign["network_id"].to_s+"/campaigns"
                  
                  @data_conversion = conversion_hash["campaign_id"+campaign["cpc_plan_id"].to_s]
                  
                  if @data_conversion.to_i > 0
                      
                      if @click.to_i > 0
                          @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                      end
                      if @total_cost.to_i > 0
                          @cpa = @total_cost.to_f / @data_conversion.to_f
                      end
                  end
                  
                  if @csv.to_i == 2
                      csv_array << [campaign["cpc_plan_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc,@ctr,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,"0","0",@avg_pos.to_f,"0","0"] 
                      # csv_array << [campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][2],network_hash["id"+campaign["network_id"].to_s][0],campaign["cpc_plan_id"].to_i,campaign["campaign_name"].to_s,@status.to_s,campaign["budget"].to_s,campaign["negative_words"].to_s,campaign["exact_negative_words"].to_s,"",""]
                  elsif @csv.to_i == 1
                      csv_array << [campaign["cpc_plan_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc,@ctr,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,"0","0",@avg_pos.to_f,"0","0"]
                  else
                      data_array << [campaign["cpc_plan_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc,@ctr,@data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,"0","0",@avg_pos.to_f,"0","0",campaign["network_id"].to_i,@account_link]
                  end
              end
              
              
               
              if campaign["network_type"] == "360"
                  
                      if threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"display"]
                          @impression = threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"display"]
                      else
                          @impression = 0
                      end
                      
                      if threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"clicks"]
                          @click = threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"clicks"]
                      else
                          @click = 0
                      end
                      
                      if threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"total_cost"]
                          @total_cost = threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"total_cost"]
                      else
                          @total_cost = 0
                      end
                      
                      if threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"avg_position"]
                          @avg_pos = threesixty_report_hash["campaign_id"+campaign['campaign_id'].to_s+"avg_position"]
                      else
                          @avg_pos = 0
                      end
                      
                      if @total_cost.to_f > 0 && @click.to_f > 0
                          @cpc = @total_cost.to_f/@click.to_f
                      end
                      if @click.to_f > 0 && @impression.to_f > 0
                          @ctr = (@click.to_f/@impression.to_f)*100
                      end
                       
                      if @avg_pos > 0 && @impression > 0
                          @avg_pos = @avg_pos.to_f / @impression.to_f
                      end
                      
                      @link = "/campaigns/"+campaign["campaign_id"].to_s+"/threesixty/"+campaign["network_id"].to_s+"/adgroup"
                      @account_link = "/channel/"+campaign["network_id"].to_s+"/campaigns"
                      
                      @data_conversion = conversion_hash["campaign_id"+campaign["campaign_id"].to_s]
                      
                      if @data_conversion.to_i > 0
                          
                          if @click.to_i > 0
                              @conv_rate = (@data_conversion.to_f / @click.to_f) * 100
                          end
                          if @total_cost.to_i > 0
                              @cpa = @total_cost.to_f / @data_conversion.to_f
                          end  
                      end

                  if @csv.to_i == 2
                      negative_words = ""
                      exact_negative_words = ""
                      
                      if campaign["negative_words_mode"].to_s == "phrase"
                          negative_words = campaign["negative_words_mode"].to_s
                      else
                          exact_negative_words = campaign["negative_words_mode"].to_s
                      end
                      
                      # edit_csv_array << [campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][2],network_hash["id"+campaign["network_id"].to_s][0],campaign["campaign_id"].to_i,campaign["campaign_name"].to_s,@status.to_s,campaign["budget"].to_s,negative_words.to_s,exact_negative_words.to_s,campaign["start_date"].to_s,campaign["end_date"].to_s]
                      csv_array << [campaign["campaign_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc, @ctr, @data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["campaign_id"+campaign["campaign_id"].to_s+"revenue"].to_f,"0",@avg_pos.to_f,"0","0"]
                  elsif @csv.to_i == 1
                      csv_array << [campaign["campaign_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc, @ctr, @data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["campaign_id"+campaign["campaign_id"].to_s+"revenue"].to_f,"0",@avg_pos.to_f,"0","0"]
                  else
                      data_array << [campaign["campaign_id"].to_i,@status.to_s,campaign["campaign_name"].to_s,@link,network_hash["id"+campaign["network_id"].to_s][2],network_hash["id"+campaign["network_id"].to_s][0],network_hash["id"+campaign["network_id"].to_s][1].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc, @ctr, @data_conversion.to_i,@conv_rate.to_f,@cpa.to_f,conversion_hash["campaign_id"+campaign["campaign_id"].to_s+"revenue"].to_f,"0",@avg_pos.to_f,"0","0",campaign["network_id"].to_i,@account_link]
                  end
              end
              
          end
      end
      
      
            
      
      
      
      if @csv.to_i == 1 || @csv.to_i == 2
        
        
            @user_company.each do |doc|
              @user_company_name = doc["name"]
            end
            
            if @export_csv_start_date == @export_csv_end_date then
                @filename = @user_company_name.to_s.downcase + "_all_campaign_(" + @export_csv_start_date +")"
            else
                @filename = @user_company_name.to_s.downcase + "_all_campaign_(" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
            end 
            
            # csv_array << [campaign["network_id"].to_s,network_hash["id"+campaign["network_id"].to_s][2],network_hash["id"+campaign["network_id"].to_s][0],campaign["campaign_id"].to_i,campaign["campaign_name"].to_s,@status.to_s,campaign["budget"].to_s,negative_words.to_s,exact_negative_words.to_s,campaign["start_date"].to_s,campaign["end_date"].to_s]
            if @csv.to_i == 1
                head = ["\xEF\xBB\xBFID","\xEF\xBB\xBFStatus", "\xEF\xBB\xBFCampaign", "\xEF\xBB\xBFLink", "\xEF\xBB\xBFChannel", "\xEF\xBB\xBFChannel ID", "\xEF\xBB\xBFAccount Name", "Currency", "Impr.", "Clicks", "Cost", "CPC", "CTR", "Conversion", "Conv. Rate", "CPA", "Revenue", "Profit", "Avg. Pos.", "RPA", "ROAS"]
            elsif @csv.to_i == 2
                head = ["\xEF\xBB\xBFNetwork ID", "\xEF\xBB\xBFNetwork Type", "\xEF\xBB\xBFAccount Name", "\xEF\xBB\xBFCampaign ID", "\xEF\xBB\xBFCampaign Name", "Status", "Budget", "Negative Words", "Exact Negative Words", "Campaign Start Date(360 only)", "Campaign End Date(360 only)"]
            end
            
            if !@filter_object.nil?
                csv_array = filter_object_campaign(@filter_object, csv_array)
            end
            
            # scores.delete_if {|score| score < 80 }  
            # csv(@filename,head,csv_array)
            excel(@filename,head,csv_array)
            
      else
        
            if !@filter_object.nil?
                data_array = filter_object_campaign(@filter_object, data_array)
            end
            
            if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
                
                # 1: "campaign" 
                # 3: channel
                # 4: account
                # 5: currency
                # 6: impression
                # 7: clicks
                # 8: cost
                # 9: cpc
                # 10: ctr
                # 11: conversion
                # 12: conv rate
                # 13: cpa
                # 14: revenue
                # 15: profit
                # 16: avg pos
                # 17: rpa
                # 18: roas
                
                if @sort_method.to_s == "asc"
                    # data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                    # data_array.sort_by{|k|k[@sort_column.to_i]}   2.6 min
                    
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                else
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
        
            
        
            data = {
              :draw => @draw,
              :recordsTotal => data_array.count.to_i,
              :recordsFiltered => data_array.count.to_i,
              :data => data_array.drop(@skip_data.to_i).first(@length.to_i),
              # :data => data_array,
              # :data => [],
              :status => "true"
            }
            
            return render :json => data, :status => :ok
      end  
      
      rescue Exception
          data = {:message => "Our System is updating, please try again later.", :status => "false"}
          return render :json => data, :status => :ok
      end
  end
  
  
  
  
  
  
  
  def getbulkjob
    
      csv_array = []     
      data_array = []
      network_list_hash = Hash.new()
      
      @draw = params[:draw]
      @length = params[:length]
      
      @skip_data = params[:start]
      
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      
      @csv = params[:csv]
      @order = params[:order]
      
      @channel_array = params[:channel_array]
      @filter_account_array = params[:account_array]
      
      @user_network_array = []
      
      if !@filter_account_array.nil?
          @filter_account_array.each do |filter_network|
              @user_network_array << filter_network.to_i
          end
      else
        
          @user_network = @db[:network_user].find('user' => session[:user_id].to_i)
          @db.close
        
          @user_network.each do |user_network|
              @user_network_array << user_network["network_id"]
          end
      end
      
      @export_csv_start_date = nil 
      @export_csv_end_date = nil
      
      
      if @end_date.nil?
          request_start_date = @today
          @export_csv_end_date = request_start_date
          @end_date = request_start_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      else
          session[:bulk_end_date] = @end_date.to_date
          @export_csv_end_date = @end_date.to_date
          @end_date = @end_date.to_date
          @end_date = @end_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      end
      @export_csv_end_date = @export_csv_end_date.strftime("%Y-%m-%d")+" 23:59:59 CST"
      


      if @start_date.nil?
          request_start_date = @today - 9.days
          @export_csv_start_date = @today - 9.days
          @start_date = request_start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"
      else
          session[:bulk_start_date] = @start_date.to_date
          @export_csv_start_date = @start_date.to_date
          @start_date = @start_date.to_date
          @start_date = @start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"
      end
      
      @export_csv_start_date = @export_csv_start_date.strftime("%Y-%m-%d")+" 00:00:00 CST"

      @network = @db[:network].find('type' => { "$in" => @channel_array},'id' => { "$in" => @user_network_array})
      @network.each do |network_d|
        network_list_hash[network_d['id'].to_s] = network_d['name'].to_s
      end
      
      
      
      
      
      
      # @bulkjob = @db2[:bulkjob].find({"$and" =>[{"$or" => [{:network_type => { "$in" => @channel_array}, :network_id => { "$in" => @user_network_array}},{"$and" => [{:user_email => @current_user_email.to_s},{:bulk_type => "edit"}]}]}, {:request_date => { '$gte' => @start_date.to_s, '$lte' => @end_date.to_s }}]})
      @bulkjob = @db2[:bulkjob].find(:user_email => @current_user_email.to_s, :request_date => { '$gte' => @start_date.to_s, '$lte' => @end_date.to_s})
      @db2.close()
      
      recordsTotal = @bulkjob.count.to_i
      
      if @bulkjob.count.to_i > 0 
          @bulkjob.each do |bulkjob_d|
            
              status = bulkjob_d['status']
              
              start = 0
              cancel = 0
              
              if bulkjob_d['status'].to_i == 0
                cancel = 1
                status = "Pending"
              elsif bulkjob_d['status'].to_i == 1
                status = "Processing"
              elsif bulkjob_d['status'].to_i == 2
                status = "Complete"
              elsif bulkjob_d['status'].to_i == 3
                cancel = 1
                start = 1
                status = "On Hold"
              elsif bulkjob_d['status'].to_i == 4
                status = "Error"
              elsif bulkjob_d['status'].to_i == 5
                status = "Cancel"
              end
            
              if @csv.to_i == 1
                  csv_array << [bulkjob_d['network_id'],network_list_hash[bulkjob_d['network_id'].to_s],bulkjob_d['network_type'],bulkjob_d['upload_type'],bulkjob_d['bulk_type'],bulkjob_d['file_id'],status.to_s,bulkjob_d['msg'].to_s,bulkjob_d['request_date'],bulkjob_d['last_update'].to_s]
              else
                  data_array  << [bulkjob_d['_id'].to_s,network_list_hash[bulkjob_d['network_id'].to_s].to_s,bulkjob_d['network_type'].to_s,bulkjob_d['upload_type'],bulkjob_d['bulk_type'],bulkjob_d['file_id'],status.to_s,bulkjob_d['msg'].to_s,bulkjob_d['request_date'],bulkjob_d['last_update'].to_s,start,cancel]
              end
          end
      end

      if @csv.to_i == 1

          if @export_csv_start_date == @export_csv_end_date then
              @filename = "Bulk_job_" + @export_csv_start_date 
          else
             @filename = "Bulk_job_" + @export_csv_start_date + "-" + @export_csv_end_date + ")"
          end
          head = ["\xEF\xBB\xBFNetwork ID", "\xEF\xBB\xBFAccount Name", "\xEF\xBB\xBFChannel Type", "Apply Level", "Add/Edit", "File ID", "Status", "Message", "Sumbit Date", "Last Update"]
          # csv(@filename,head,csv_array)
          excel(@filename,head,csv_array)
      else
        
        
          if !@order.nil? 
                @sort_column = @order["0"]["column"]
                @sort_method = @order["0"]["dir"]
             
                if @sort_method.to_s == "asc"
                    # data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                    # data_array.sort_by{|k|k[@sort_column.to_i]}   2.6 min
                    
                    # data_array.sort { |a,b| a[@sort_column.to_i] <=> b[@sort_column.to_i] }
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}
                    
                else
                    data_array = data_array.sort_by{|k|k[@sort_column.to_i]}.reverse
                end
            end
        
        
            @data = {
                    :draw => @draw,
                    :recordsTotal => recordsTotal,
                    :recordsFiltered => data_array.count.to_i,
                    :data => data_array.drop(@skip_data.to_i).first(@length.to_i),
                    # :data => data_array,
                    # :data => [],
                    :status => "true"
            }
            return render :json => @data, :status => :ok      
      end

  end
  
  
  
  
  
  
  
  
  
  
  def excel(name,head,array)
    
     p = Axlsx::Package.new
     wb = p.workbook
      
     wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
        
         sheet.add_row head
         
         array.each_with_index do |csv, csv_index|
            sheet.add_row csv
         end
     end
     
     create_excel_path = '/home/bmg/adeqo/public/export_excel/'+name+'.xlsx'
     p.serialize(create_excel_path)
     
     send_file create_excel_path, :disposition => "attachment; filename=#{name}.xlsx"
  end
  
  def csv(name,head,array)
                  
     file = CSV.generate do |csv|
        
          csv << head
          
          array.each do |csv_data|
              csv_data.each_with_index do |csv_data_d, index|
                  if index.to_i == 1 || index.to_i == 4 
                        csv_data_d = "\xEF\xBB\xBF"+csv_data_d.to_s                          
                  end
              end
               
              csv << csv_data
          end                
      end
   
      send_data file, :type => 'text/csv; header=present', :disposition => "attachment; filename=#{name}.csv"
      
  end
  
  
  
  
  def filter_object_click_activity(filter, data_array)
    
          filter.each do |filter_object|
            
              if filter_object[1]['name'].downcase.to_s == "campaign_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[0].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[0].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[0] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[0].slice(0, compare_char) == filter_object[1]['value']}
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "adgroup_name"
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[1].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[1].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[1] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[1].slice(0, compare_char) == filter_object[1]['value']}
                  end
              end              
          end
          
          return data_array
  end
  
  
  
  
  
  # data_array << [keyword_d["keyword_id"].to_i,@status.to_s,@name.to_s, keyword_d["keyword"].to_s,@match.to_s,@visit_url_durl.to_s,@m_visit_url_durl,keyword_d["price"].to_f,@cpc.to_f,@display.to_f,@clicks.to_f,@click_rate.to_f,@total_cost.to_f, @data_conversion.to_i, @conv_rate.to_f,  @cpa.to_f, 0, 0, 0,@avg_pos.to_f,0,0,@visit_url.to_s,@m_visit_url.to_s]
  def filter_object_keyword(filter, data_array)
          filter.each do |filter_object|
            
              if filter_object[1]['name'].downcase.to_s == "status"
                
                  if filter_object[1]['value'].downcase == "active"
                      data_array = data_array.select { |u| u[1].downcase == filter_object[1]['value'].downcase}
                  else
                      data_array = data_array.select { |u| u[1].downcase.include?(filter_object[1]['value'].downcase) }
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "adgroup_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[2].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[2].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[2] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[2].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "final_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[5].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[5].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[5] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[5].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "m_final_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[6].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[6].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[6] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[6].slice(0, compare_char) == filter_object[1]['value']}
                  end
                                      
                                  
              elsif filter_object[1]['name'].downcase.to_s == "max_cpc"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[7] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[7] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[7] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[7] < filter_object[1]['value'].strip.to_f}  
                  end

                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[7] > filter_object[1]['value'].strip.to_f}  
                  end

                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[7] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              
              elsif filter_object[1]['name'].downcase.to_s == "avg_cpc"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[12] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[12] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[12] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[12] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[12] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[12] != filter_object[1]['value'].strip.to_f}  
                  end   
              
              elsif filter_object[1]['name'].downcase.to_s == "impr"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[8] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[8] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[8] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[8] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[8] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[8] != filter_object[1]['value'].strip.to_f}  
                  end 
                      
              elsif filter_object[1]['name'].downcase.to_s == "clicks"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[9] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[9] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[9] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[9] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[9] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[9] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ctr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[10] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[10] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[10] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[10] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[10] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[10] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "cost"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[11] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[11] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[11] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[11] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[11] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[11] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "conv"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[13] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[13] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[13] <= filter_object[1]['value'].strip.to_f}  
                  end    
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[13] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[13] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[13] != filter_object[1]['value'].strip.to_f}  
                  end
              elsif filter_object[1]['name'].downcase.to_s == "conv_rate"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[14] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[14] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[14] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[14] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[14] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[14] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[15] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[15] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[15] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[15] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[15] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[15] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cpm"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[16] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[16] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[16] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[16] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[16] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[16] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "revenue"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[17] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[17] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[17] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[17] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[17] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[17] != filter_object[1]['value'].strip.to_f}  
                  end
                  
                  
              elsif filter_object[1]['name'].downcase.to_s == "profit"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[18] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[18] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[18] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[18] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[18] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[18] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "avg_pos"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[19] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[19] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[19] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[19] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[19] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[19] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "rpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[20] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[20] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[20] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[20] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[20] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[20] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "roas"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[21] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[21] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[21] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[21] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[21] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[21] != filter_object[1]['value'].strip.to_f}  
                  end
                   
              end              
          end
          
          return data_array
  end
  
  
  
  
  
  
  
  # array_data << [ad_d["ad_id"].to_i,@status.to_s,@name.to_s,@title.to_s,@desc1.to_s,@desc2.to_s,@visiturl.to_s,@showurl.to_s,@adtype.to_s,@max_cpc.to_f,@cpc.to_f,@display.to_i,@click.to_i,@click_rate.to_f,@cost.to_i,0,0,0,0,0,0,0,0,0]
  def filter_object_ad(filter, data_array)
          filter.each do |filter_object|
            
              if filter_object[1]['name'].downcase.to_s == "status"
                
                  if filter_object[1]['value'].downcase == "active"
                      data_array = data_array.select { |u| u[1].downcase == filter_object[1]['value'].downcase}
                  else
                      data_array = data_array.select { |u| u[1].downcase.include?(filter_object[1]['value'].downcase) }
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "adgroup_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[2].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[2].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[2] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[2].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "headline"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[3].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[3].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[3] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[3].slice(0, compare_char) == filter_object[1]['value']}
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "desc_1"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[4].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[4].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[4] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[4].slice(0, compare_char) == filter_object[1]['value']}
                  end        
              
              elsif filter_object[1]['name'].downcase.to_s == "desc_2"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[5].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[5].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[5] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[5].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "display_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[6].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[6].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[6] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[6].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "final_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[7].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[7].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[7] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[7].slice(0, compare_char) == filter_object[1]['value']}
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "m_display_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[8].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[8].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[8] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[8].slice(0, compare_char) == filter_object[1]['value']}
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "m_final_url"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[9].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[9].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[9] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[9].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ad_type"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[10].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[10].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[10] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[10].slice(0, compare_char) == filter_object[1]['value']}
                  end
              
                                                
              elsif filter_object[1]['name'].downcase.to_s == "avg_cpc"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[15] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[15] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[15] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[15] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[15] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[15] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "impr"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      # # @logger.info ">="
                      data_array = data_array.select { |u| u[11].to_i >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      # # @logger.info "="
                      data_array = data_array.select { |u| u[11].to_i == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      # # @logger.info "<="
                      data_array = data_array.select { |u| u[11].to_i <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[11] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[11] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[11] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "clicks"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[12] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[12] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[12] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[12] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[12] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[12] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ctr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[13] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[13] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[13] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[13] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[13] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[13] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "cost"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[14] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[14] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[14] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[14] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[14] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[14] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "conv"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[16] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[16] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[16] <= filter_object[1]['value'].strip.to_f}  
                  end    
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[16] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[16] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[16] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv_rate"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[17] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[17] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[17] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[17] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[17] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[17] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[18] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[18] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[18] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[18] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[18] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[18] != filter_object[1]['value'].strip.to_f}  
                  end
              elsif filter_object[1]['name'].downcase.to_s == "cpm"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[20] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[20] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[20] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[20] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[20] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[20] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "revenue"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[21] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[21] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[21] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[21] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[21] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[21] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "profit"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[22] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[22] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[22] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[22] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[22] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[22] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "avg_pos"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[23] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[23] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[23] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[23] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[23] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[23] != filter_object[1]['value'].strip.to_f}  
                  end
                  
                  
              elsif filter_object[1]['name'].downcase.to_s == "rpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[24] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[24] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[24] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[24] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[24] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[24] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "roas"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[25] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[25] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[25] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[25] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[25] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[25] != filter_object[1]['value'].strip.to_f}  
                  end
              end              
          end
          
          return data_array
  end
  
  
  
  
  
  
  
  # @adgroup << [adgroup_d["adgroup_id"].to_i, @status.to_s, @name.to_s, @max_cpc.to_f, @display.to_i ,@click.to_i, @click_rate, @cost.to_f,@cpc.to_f,0,0,0,0,0,0,0,0]
  def filter_object_adgroup(filter, data_array)
          filter.each do |filter_object|
            
              if filter_object[1]['name'].downcase.to_s == "status_bak"
                
                  # if filter_object[1]['value'].downcase == "active"
                      # data_array = data_array.select { |u| u[1].downcase == filter_object[1]['value'].downcase}
                  # else
                      # data_array = data_array.select { |u| u[1].downcase.include?(filter_object[1]['value'].downcase) }
                  # end
                  
              elsif filter_object[1]['name'].downcase.to_s == "adgroup_name_bak"
                
                  # if filter_object[1]['rule'].to_s == "**"
                      # data_array = data_array.select { |u| u[2].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "!**"
                      # data_array = data_array.select { |u| !u[2].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "="
                      # data_array = data_array.select { |u| u[2] == filter_object[1]['value']}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "*="
                      # compare_char = filter_object[1]['value'].length
                      # data_array = data_array.select { |u| u[2].slice(0, compare_char) == filter_object[1]['value']}
                  # end
                  
              elsif filter_object[1]['name'].downcase.to_s == "max_cpc"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[3] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[3] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[3] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[3] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[3] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[3] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "impr"
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[4] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[4] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[4] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[4] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[4] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[4] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "clicks"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[5] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[5] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[5] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[5] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[5] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[5] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ctr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[6] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[6] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[6] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[6] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[6] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[6] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "cost"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[7] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[7] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[7] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[7] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[7] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[7] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "avg_cpc"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[8] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[8] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[8] <= filter_object[1]['value'].strip.to_f}  
                  end    
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[8] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[8] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[8] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[9] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[9] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[9] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[9] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[9] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[9] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv_rate"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[10] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[10] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[10] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[10] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[10] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[10] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[11] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[11] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[11] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[11] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[11] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[11] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "revenue"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[12] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[12] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[12] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[12] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[12] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[12] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "avg_pos"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[13] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[13] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[13] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[13] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[13] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[13] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "rpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[14] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[14] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[14] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[14] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[14] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[14] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "roas"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[15] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[15] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[15] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[15] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[15] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[15] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              end              
          end
          
          return data_array
  end
  
  
  # sad
  # csv_array << [network["id"],network["name"],"Sogou",@impression.to_i,@click.to_i,@total_cost.to_i,@ctr.to_i,@data_conversion.to_i,@conv_rate.to_f,"0"]
  def filter_object_network(filter, data_array)
    
          filter.each do |filter_object|
                  
              if filter_object[1]['name'].downcase.to_s == "account_name"
                
                  if filter_object[1]['rule'].to_s == "**"
                      data_array = data_array.select { |u| u[1].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!**"
                      data_array = data_array.select { |u| !u[1].include?(filter_object[1]['value'])}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[1] == filter_object[1]['value']}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "*="
                      compare_char = filter_object[1]['value'].length
                      data_array = data_array.select { |u| u[1].slice(0, compare_char) == filter_object[1]['value']}  
                  end
                  
                  
              elsif filter_object[1]['name'].downcase.to_s == "impr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[3] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[3] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[3] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[3] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[3] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[3] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "clicks"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[4] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[4] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[4] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[4] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[4] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[4] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cost"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[5] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[5] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[5] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[5] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[5] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[5] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ctr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[6] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[6] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[6] <= filter_object[1]['value'].strip.to_f}  
                  end    
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[6] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[6] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[6] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[7] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[7] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[7] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[7] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[7] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[7] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv_rate"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[8] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[8] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[8] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[8] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[8] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[8] != filter_object[1]['value'].strip.to_f}  
                  end
                  
                                
              elsif filter_object[1]['name'].downcase.to_s == "revenue"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[9] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[9] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[9] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[9] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[9] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[9] != filter_object[1]['value'].strip.to_f}  
                  end
                                
              end              
          end
          
          return data_array
  end
  
  
  
  
  # three_sixty["campaign_id"].to_i,@status.to_s,three_sixty["campaign_name"].to_s,@link,network["type"],network["name"],network["currency"].upcase,@impression,@click.to_i,@total_cost.to_i,@cpc, @ctr, @conversion.count.to_i,@conv_rate.to_f,@cpa.to_f,"0","0","0","0","0"
  def filter_object_campaign(filter, data_array)
    
          filter.each do |filter_object|
            
              if filter_object[1]['name'].downcase.to_s == "status_bak"
                
                  # if filter_object[1]['value'].downcase == "active"
                      # data_array = data_array.select { |u| u[1].downcase == filter_object[1]['value'].downcase}
                  # else
                      # data_array = data_array.select { |u| u[1].downcase.include?(filter_object[1]['value'].downcase) }
                  # end
                  
              elsif filter_object[1]['name'].downcase.to_s == "campaign_name_bak"
                
                  # if filter_object[1]['rule'].to_s == "**"
                      # data_array = data_array.select { |u| u[2].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "!**"
                      # data_array = data_array.select { |u| !u[2].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "="
                      # data_array = data_array.select { |u| u[2] == filter_object[1]['value']}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "*="
                      # compare_char = filter_object[1]['value'].length
                      # data_array = data_array.select { |u| u[2].slice(0, compare_char) == filter_object[1]['value']}  
                  # end
                  
              elsif filter_object[1]['name'].downcase.to_s == "account_name_bak"
                  # if filter_object[1]['rule'].to_s == "**"
                      # data_array = data_array.select { |u| u[5].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "!**"
                      # data_array = data_array.select { |u| !u[5].include?(filter_object[1]['value'])}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "="
                      # data_array = data_array.select { |u| u[5] == filter_object[1]['value']}  
                  # end
#                   
                  # if filter_object[1]['rule'].to_s == "*="
                      # compare_char = filter_object[1]['value'].length
                      # data_array = data_array.select { |u| u[5].slice(0, compare_char) == filter_object[1]['value']}
                  # end
                
              
              elsif filter_object[1]['name'].downcase.to_s == "currency"  
                  data_array = data_array.select { |u| u[6].downcase == filter_object[1]['value'].downcase}
                  
              elsif filter_object[1]['name'].downcase.to_s == "impr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[7] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[7] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[7] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[7] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[7] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[7] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "clicks"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[8] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[8] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[8] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[8] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[8] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[8] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cost"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[9] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[9] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[9] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[9] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[9] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[9] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "avg_cpc"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[10] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[10] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[10] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[10] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[10] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[10] != filter_object[1]['value'].strip.to_f}  
                  end
              
              elsif filter_object[1]['name'].downcase.to_s == "ctr"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[11] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[11] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[11] <= filter_object[1]['value'].strip.to_f}  
                  end    
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[11] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[11] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[11] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[12] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[12] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[12] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[12] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[12] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[12] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "conv_rate"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[13] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[13] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[13] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[13] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[13] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[13] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "cpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[14] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[14] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[14] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[14] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[14] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[14] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "revenue"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[15] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[15] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[15] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[15] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[15] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[15] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "profit"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[16] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[16] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[16] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[16] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[16] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[16] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "avg_pos"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[17] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[17] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[17] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[17] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[17] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[17] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "rpa"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[18] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[18] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[18] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[18] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[18] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[18] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              elsif filter_object[1]['name'].downcase.to_s == "roas"  
                  
                  if filter_object[1]['rule'].to_s == ">="
                      data_array = data_array.select { |u| u[19] >= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "="
                      data_array = data_array.select { |u| u[19] == filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<="
                      data_array = data_array.select { |u| u[19] <= filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "<"
                      data_array = data_array.select { |u| u[19] < filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == ">"
                      data_array = data_array.select { |u| u[19] > filter_object[1]['value'].strip.to_f}  
                  end
                  
                  if filter_object[1]['rule'].to_s == "!="
                      data_array = data_array.select { |u| u[19] != filter_object[1]['value'].strip.to_f}  
                  end
                  
              end              
          end
          
          return data_array
  end
  
  
  
  def bulkaddkeyword
    
      begin
          file = params[:file]
          
          campaign_type = params[:campaign_type]
          campaign_id = params[:campaign_id]
          network_id = params[:network_id]
          
          #Adgroup Name(Require)  Max Price(Optional) Pause(Optional)
          # @logger.info "bulkaddkeyword start" 
          
          if campaign_type.to_s == "" || campaign_id.to_s == "" || network_id.to_s == ""
              return render :text => "Your request is invalid. Please try again."
          end
          
          if campaign_type == "threesixty"
              campaign_type = "360"
          end
          
          
          begin
              xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
          rescue Exception
              return render :text => "File type error, Exexl File(.xlsx) only."
          end
          
            
          @network = @db[:network].find('id' => network_id.to_i, 'type' => campaign_type.to_s).limit(1)
          @db.close
          
          if @network.count.to_i != 1 
              # @logger.info "bulkaddkeyword , no account result in db"
              return render :text => "Your request is invalid. Please try again."
          end
          
          login = 0
          update_msg_array = []
          temp_network_name = ""
          temp_campaign_name = ""
          temp_adgroup_id = 0
          temp_360_account_id = ""  
            
          if campaign_type.to_s == "sogou"
              @campaign = @db["all_campaign"].find('cpc_plan_id' => campaign_id.to_i, 'network_type' => "sogou")
              @db.close
          end
          
          if campaign_type.to_s == "360"
              @campaign = @db["all_campaign"].find('campaign_id' => campaign_id.to_i, 'network_type' => "360")
              @db.close
          end
          
          if @campaign.count.to_i > 0
              @campaign.each do |campaign_d|
                  temp_campaign_name = campaign_d['campaign_name']
              end
          end
          
            
          if @network.count.to_i > 0
              @network.each do |network_d|
                  temp_network_name = network_d["name"].to_s  
                  
                  @company_id = network_d["company_id"]
                  @tracking_type = network_d["tracking_type"]
                  
                  if network_d["type"].to_s == "360"
                      @username = network_d["username"]
                      @password = network_d["password"]
                      @apitoken = network_d["api_token"]
                      @apisecret = network_d["api_secret"]
                      temp_360_account_id = network_d["accountid"]
                      
                      login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                      @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                      
                      if @refresh_token.nil?
                          return render :text => "API Info is invalid, Please Check your API Info and Token is correct in Adeqo."
                      else
                          @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                                                      
                          @remain_quote = @response.headers["quotaremain"].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                          end
                      end
                  end
                  
                  if network_d["type"].to_s == "sogou"
                        
                      sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                      sogou_result = @sogou_api.call(:get_account_info)
                                              
                      if sogou_result.header[:res_header][:desc].to_s == "success"
                          @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                              sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcService")
                          end
                      else
                          return render :text => "Account " + network_d["name"] + " " + sogou_result.header[:res_header][:failures][:message].to_s
                      end                        
                  end
                  
              end
          end 
           # joe
          update_msg_array << "Complete.<br />"
            
          if login == 1
              xlsx.each_with_index do |csv, csv_index|
                  if csv_index.to_i != 0
                      row = csv_index.to_i + 1
                      
                      if csv[0].to_s != "" && csv[1].to_s != "" && csv[5].to_s != ""
                          
                          if campaign_type.to_s == "sogou"
                              
                              if @remain_quote.to_i <= 500
                                  update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                  return render :text => update_msg_array.join("<br />")
                              else
                                
                                  db_name = "adgroup_sogou_"+network_id.to_s
                                  @adgroup = @db[db_name].find('name' => csv[0].to_s, 'cpc_plan_id'=> campaign_id.to_i).limit(1)
                                  @db.close
                                  
                                  if @adgroup.count.to_i > 0
                                      @adgroup.each_with_index do |adgroup, adgroup_index|
                                          temp_adgroup_id = adgroup["cpc_grp_id"]
                                      end
                                      
                                      requesttypearray = []
                                      requesttype = {}
                                            
                                      requesttype[:cpcGrpId]    =  temp_adgroup_id
                                      requesttype[:cpc]    =  csv[1].to_s
                                      requesttype[:price]    =  csv[2].to_f
                                      requesttype[:isShow]    =  csv[7].to_i
                                      
                                      if csv[6].to_s != ""
                                          if csv[6].to_s.downcase == "false"
                                              pause = "false"
                                          else
                                              pause = "true"
                                          end
                                          
                                          requesttype[:pause]    =  pause.to_s.downcase
                                      else
                                          pause = "true"
                                          requesttype[:pause]    =  pause.to_s.downcase
                                      end
                                      
                                      if csv[5].to_s != ""
                                          if csv[5].to_s == "exact"
                                              matchType = 0
                                          elsif csv[5].to_s == "pharse"
                                              matchType = 1
                                          elsif csv[5].to_s == "board"
                                              matchType = 2
                                          else
                                              matchType = 0
                                          end
                                          
                                          requesttype[:matchType]    =  matchType.to_i
                                      end
                                      
                                      url = csv[3].to_s
                                      if csv[3].to_s != ""
                                          if !url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" 
                                            url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                            url = url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+temp_adgroup_id.to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                            url = url + "&tv=v1&durl="+CGI.escape(csv[3].to_s)
                                          end
                                          requesttype[:visitUrl]    =  url.to_s
                                      end
                                      
                                      m_url = csv[4].to_s
                                      if csv[4].to_s != ""
                                          if !m_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo" 
                                            m_url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                            m_url = m_url + "&campaign_id="+campaign_id.to_s+"&adgroup_id="+temp_adgroup_id.to_s+"&ad_id={creative}&keyword_id={keywordid}"
                                            m_url = m_url + "&tv=v1&durl="+CGI.escape(csv[4].to_s)
                                          end
                                          requesttype[:mobileVisitUrl]    =  m_url.to_s
                                      end
                                      
                                      requesttypearray << requesttype
                                      
                                      # @logger.info requesttype
                                      
                                      @update_status = @sogou_api.call(:add_cpc, message: { cpcTypes: requesttypearray })
                                      @header = @update_status.header.to_hash
                                      
                                      @msg = @header[:res_header][:desc]
                                      @remain_quote = @header[:res_header][:rquota]
                                      
                                      # @logger.info @header
                                        
                                      @update_status_body = @update_status.body.to_hash
                                      # @logger.info @update_status_body
                                      
                                      
                                      if @msg.to_s.downcase == "success"
                                          # update_msg_array << "Row " + row.to_s + " keyword add to "+ csv[0].to_s + " Success."
                                          
                                          db_name = "keyword_sogou_"+network_id.to_s
                                          @db[db_name].insert_one({ 
                                                                          network_id: network_id.to_i,
                                                                          cpc_plan_id: campaign_id.to_i, 
                                                                          cpc_grp_id: @update_status_body[:add_cpc_response][:cpc_types][:cpc_grp_id].to_i,
                                                                          keyword_id: @update_status_body[:add_cpc_response][:cpc_types][:cpc_id].to_i,
                                                                          keyword: @update_status_body[:add_cpc_response][:cpc_types][:cpc].to_s,
                                                                          price: @update_status_body[:add_cpc_response][:cpc_types][:price].to_f, 
                                                                          visit_url: url.to_s,
                                                                          mobile_visit_url: m_url.to_s,
                                                                          match_type: @update_status_body[:add_cpc_response][:cpc_types][:match_type].to_i,
                                                                          pause: @update_status_body[:add_cpc_response][:cpc_types][:pause].to_s,
                                                                          status: @update_status_body[:add_cpc_response][:cpc_types][:status].to_i,
                                                                          cpc_quality: @update_status_body[:add_cpc_response][:cpc_types][:cpc_quality].to_f,
                                                                          active: 0,
                                                                          display: 0,
                                                                          use_grp_price: @update_status_body[:add_cpc_response][:cpc_types][:opt][:opt_long][:value].to_i,
                                                                          mobile_match_type: 3,
                                                                          keyword_not_show_reason: "",
                                                                          keyword_not_approve_reason: "",
                                                                          update_date: @now,                                            
                                                                          create_date: @now })
                                          @db.close
                                      
                                      else
                                          update_msg_array << "Row " + row.to_s + " is not added. " + @header[:res_header][:failures][:message].to_s   
                                      end
                                      
                                  else
                                      # @logger.info "bulkaddadgroup , no adgroup result found"
                                      update_msg_array << "Row " + row.to_s + " : " + " Adgroup name is invalid. Please try again."
                                  end
                                    
                              end
                              
                          end
                          
                          if campaign_type.to_s == "360"
                              
                              if @remain_quote.to_i <= 500
                                  update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                  return render :text => update_msg_array.join("<br />")
                              else
                                
                                  db_name = "adgroup_360_"+network_id.to_s
                                  @adgroup = @db[db_name].find('adgroup_name' => csv[0].to_s, 'campaign_id'=> campaign_id.to_i).limit(1)
                                  @db.close
                                  
                                  if @adgroup.count.to_i > 0
                                      @adgroup.each_with_index do |adgroup, adgroup_index|
                                          
                                          temp_adgroup_id = adgroup["adgroup_id"]
                                          
                                          requesttypearray = []
                                          if csv[5].to_s != ""
                                              if csv[5].to_s.downcase == "pharse"
                                                  matchType = "pharse"
                                                  dbmatchType = "短语"
                                              elsif csv[5].to_s.downcase == "board"
                                                  matchType = "board"
                                                  dbmatchType = "广泛"
                                              else
                                                  matchType = "exact"
                                                  dbmatchType = "精确"
                                              end
                                          else
                                              matchType = "exact"
                                              dbmatchType = "精确"
                                          end
                                          
                                          
                                          request_str = '{"groupId":'+temp_adgroup_id.to_s+',"word":"'+csv[1].to_s+'","price":'+csv[2].to_s+',"url":"'+csv[3].to_s+'","mobileUrl":"'+csv[4].to_s+'","matchType":"'+matchType.to_s+'"}'
                                          requesttypearray << request_str
                                          
                                          
                                          request = '['+requesttypearray.join(",")+']'
                                          # @logger.info request
                                                       
                                          body = { 
                                              'keywords' => request
                                          }
                                          
                                          @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "keyword", "add", body)
                                          @affectedRecords = @update_res["keyword_add_response"]
                                          
                                          # # @logger.info @affectedRecords
                                          # # @logger.info @update_res
                                          
                                          @remain_quote = @response.headers["quotaremain"].to_i
                                          
                                          if @update_res["keyword_add_response"]["failures"].nil?
                                              # update_msg_array << "Row " + row.to_s + " keyword add to "+temp_network_name.to_s+" Success."
                                              
                                              update_keyword_id = @update_res["keyword_add_response"]["keywordIdList"]["item"].to_i
                                              
                                              url = csv[3].to_s
                                              m_url = csv[4].to_s
                                              
                                              if url.to_s != ""
                                                  if !url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo"
                                                      requesttypearray = []
                                                      url = "http://t.adeqo.com/click?company_id="+@company_id.to_s+"&network_id="+network_id.to_s
                                                      url = url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id="+update_keyword_id.to_s
                                                      url = url + "&tv=v1&durl="+CGI.escape(csv[3].to_s)
                                                      
                                                      request_str = '{"id":'+update_keyword_id.to_s+',"url":"'+url.to_s+'"}'
                                                      requesttypearray << request_str
                                                      request = '['+requesttypearray.join(",")+']'
                                                      
                                                      body = { 
                                                          'keywords' => request
                                                      }
                                                      
                                                      @url_update_res = threesixty_api( @apitoken.to_s, @refresh_token, "keyword", "update", body)
                                                      @url_affectedRecords = @url_update_res["keyword_update_response"]["affectedRecords"]
                                                       
                                                      @remain_quote = @response.headers["quotaremain"].to_i
                                                       
                                                      # @logger.info @url_affectedRecords
                                                      # @logger.info @url_update_res
                                                  end
                                              end
                                              
                                              if m_url.to_s != ""
                                                  if !m_url.to_s.include?(".adeqo.") && @tracking_type.to_s.downcase == "adeqo"
                                                      requesttypearray = []
                                                      m_url = "http://t.adeqo.com/click?company_id=1&network_id="+network_id.to_s
                                                      m_url = m_url + "&campaign_id={planid}&adgroup_id={groupid}&ad_id={creativeid}&keyword_id="+update_keyword_id.to_s
                                                      m_url = m_url + "&tv=v1&durl="+CGI.escape(csv[4].to_s)
                                                      
                                                      request_str = '{"id":'+update_keyword_id.to_s+',"mobileUrl":"'+m_url.to_s+'"}'
                                                      requesttypearray << request_str
                                                      request = '['+requesttypearray.join(",")+']'
                                                       
                                                      body = { 
                                                          'keywords' => request
                                                      }
                                                      
                                                      @url_update_res = threesixty_api( @apitoken.to_s, @refresh_token, "keyword", "update", body)
                                                      @url_affectedRecords = @url_update_res["keyword_update_response"]["affectedRecords"]
                                                      
                                                      @remain_quote = @response.headers["quotaremain"].to_i
                                                      
                                                      # @logger.info @url_affectedRecords
                                                      # @logger.info @url_update_res
                                                  end
                                              end
    
                                              
                                              keyword_db_name = "keyword_360_"+network_id.to_s
                                              @db[keyword_db_name].insert_one({ 
                                                        network_id: network_id.to_i,
                                                        account_id: temp_360_account_id.to_i,
                                                        account_name: temp_network_name.to_s,
                                                        campaign_id: campaign_id.to_i,
                                                        campaign_name: temp_campaign_name.to_s,
                                                        adgroup_id: temp_adgroup_id.to_i,
                                                        keyword_id: @update_res["keyword_add_response"]["keywordIdList"]["item"].to_i,
                                                        keyword: csv[1].to_s,
                                                        price: csv[2].to_f, 
                                                        status: "启用",
                                                        sys_status: "有效",
                                                        match_type: dbmatchType.to_s,
                                                        visit_url: url.to_s,
                                                        mobile_visit_url: m_url.to_s,
                                                        cpc_quality: 0,
                                                        extend_ad_type: 0,
                                                        negative_words: "",
                                                        update_date: @now,                                            
                                                        create_date: @now 
                                                        })
                                              @db.close 
                                              
                                          else
                                              update_msg_array << "Row " + row.to_s + " is not added." + @update_res["keyword_add_response"]["failures"]["item"]["message"].to_s
                                          end
                                          
                                      end
                                  else
                                      update_msg_array << "Row " + row.to_s + " : " + " Adgroup name is invalid. Please try again."
                                  end
                                  
                              end
                              
                              
                          end
                          
                      else
                          update_msg_array << "Row " + row.to_s + " : Missing Require Field, Please Check your file."
                      end
                  end
              end
          end  
            
          return render :text => update_msg_array.join("<br />")
      rescue Exception
          return render :text => "Ad Channel is busy, please try again a bit later."
      end
  end
  
  
  
  
  
  def bulkaddad
      # joe
      
      begin
          file = params[:file]
          
          campaign_type = params[:campaign_type]
          campaign_id = params[:campaign_id]
          network_id = params[:network_id]
          
          #Adgroup Name(Require)  Max Price(Optional) Pause(Optional)
          # @logger.info "bulkaddad start" 
          
          
          if campaign_type.to_s == "" || campaign_id.to_s == "" || network_id.to_s == ""
              return render :text => "Your request is invalid. Please try again."
          end
          
          if campaign_type == "threesixty"
              campaign_type = "360"
          end
          
          begin
              xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
          rescue Exception
              return render :text => "File type error, Exexl File(.xlsx) only."
          end
          
          @test = 0
          
          @network = @db[:network].find('id' => network_id.to_i, 'type' => campaign_type.to_s).limit(1)
          @db.close
          
          if @network.count.to_i != 1 
              # @logger.info "bulkaddad , no account result in db"
              return render :text => "Your request is invalid. Please try again."
          end
          
          login = 0
          update_msg_array = []
          temp_network_name = ""
          temp_campaign_name = ""
          temp_adgroup_id = 0
          temp_360_account_id = ""
          
          if campaign_type.to_s == "sogou"
              @campaign = @db["all_campaign"].find('cpc_plan_id' => campaign_id.to_i, 'network_type' => "sogou")
              @db.close
          end
          
          if campaign_type.to_s == "360"
              @campaign = @db["all_campaign"].find('campaign_id' => campaign_id.to_i, 'network_type' => "360")
              @db.close
          end
          
          if @campaign.count.to_i > 0
              @campaign.each do |campaign_d|
                  temp_campaign_name = campaign_d['campaign_name']
              end
          end
          
          if @network.count.to_i > 0
              @network.each do |network_d|
                
                  temp_network_name = network_d["name"].to_s
                  
                  if network_d["type"].to_s == "360"
                      @username = network_d["username"]
                      @password = network_d["password"]
                      @apitoken = network_d["api_token"]
                      @apisecret = network_d["api_secret"]
                      temp_360_account_id = network_d["accountid"]
                      
                      login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                      @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                      
                      if @refresh_token.nil?
                          return render :text => "API Info is invalid, Please Check your API Info and Token is correct in Adeqo."
                      else
                          @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                                                      
                          @remain_quote = @response.headers["quotaremain"].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                          end
                      end
                  end
                  
                  
                  
                  if network_d["type"].to_s == "sogou"
                        
                      sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                      sogou_result = @sogou_api.call(:get_account_info)
                                              
                      if sogou_result.header[:res_header][:desc].to_s == "success"
                          @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                              sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcIdeaService")
                          end
                      else
                          return render :text => "Account " + network_d["name"] + " " + sogou_result.header[:res_header][:failures][:message].to_s
                      end                        
                  end
                  
                  
              end
          end
          
          update_msg_array << "Complete.<br />"
          
          if login == 1
              xlsx.each_with_index do |csv, csv_index|
                  if csv_index.to_i != 0
                      row = csv_index.to_i + 1
                      
                      if csv[0].to_s != "" && csv[1].to_s != "" && csv[2].to_s != "" && csv[3].to_s != "" && csv[4].to_s != ""
                        
                          if csv[1].to_s.bytes.count.to_i < 15
                              update_msg_array << "Row " + row.to_s + " : Title is too short, Please Check your file."
                          else
                            
                              if campaign_type.to_s == "sogou"
                                  
                                  if @remain_quote.to_i <= 500
                                        update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                        return render :text => update_msg_array.join("<br />")
                                  else
                                        db_name = "adgroup_sogou_"+network_id.to_s
                                        @adgroup = @db[db_name].find('name' => csv[0].to_s, 'cpc_plan_id'=> campaign_id.to_i)
                                        @db.close
                                        
                                        if @adgroup.count.to_i > 0
                                                                                
                                            @adgroup.each_with_index do |adgroup, adgroup_index|
                                                temp_adgroup_id = adgroup["cpc_grp_id"]
                                            end
                                            
                                            requesttypearray = []
                                            requesttype = {}
                                                
                                            requesttype[:cpcGrpId]    =  temp_adgroup_id
                                            requesttype[:title]    =  csv[1].to_s
                                            requesttype[:description1]    =  csv[2].to_s
                                            requesttype[:description2]    =  csv[3].to_s
                                            requesttype[:visitUrl]    =  csv[4].to_s
                                            
                                            if csv[8].to_s != ""
                                                if csv[8].to_s.downcase == "true"
                                                    pause = "true"
                                                else
                                                    pause = "false"
                                                end
                                                
                                                requesttype[:pause]    =  pause.to_s.downcase
                                            else
                                                pause = "false"
                                                requesttype[:pause]    =  pause.to_s.downcase
                                            end
                                            
                                            if csv[5].to_s != ""
                                                requesttype[:showUrl]    =  csv[5].to_s
                                            end
                                            
                                            if csv[6].to_s != ""
                                                requesttype[:mobileVisitUrl]    =  csv[6].to_s
                                            end
                                            
                                            if csv[7].to_s != ""
                                                requesttype[:mobileShowUrl]    =  csv[7].to_s
                                            end
                                            
                                            requesttypearray << requesttype
                                            
                                            @update_status = @sogou_api.call(:add_cpc_idea, message: { cpcIdeaTypes: requesttypearray })
                                            @header = @update_status.header.to_hash
                                            @msg = @header[:res_header][:desc]
                                            @remain_quote = @header[:res_header][:rquota]
                                            # @logger.info @header
                                              
                                            @update_status_body = @update_status.body.to_hash
                                            # # @logger.info @update_status_body
                                            
                                            if @msg.to_s.downcase == "success"
                                                # update_msg_array << "Row " + row.to_s + " ad add to "+ csv[0].to_s + " Success."
                                                
                                                db_name = "ad_sogou_"+network_id.to_s
                                                @db[db_name].insert_one({ 
                                                                                network_id: network_id.to_i,
                                                                                cpc_plan_id: campaign_id.to_i, 
                                                                                cpc_grp_id: @update_status_body[:add_cpc_idea_response][:cpc_idea_types][:cpc_grp_id].to_i,
                                                                                cpc_idea_id: @update_status_body[:add_cpc_idea_response][:cpc_idea_types][:cpc_idea_id].to_i,
                                                                                cpc_idea_id_2: "",
                                                                                title: csv[1].to_s, 
                                                                                description_1: csv[2].to_s, 
                                                                                description_2: csv[3].to_s, 
                                                                                visit_url: csv[4].to_s,
                                                                                show_url: csv[5].to_s,
                                                                                mobile_visit_url: csv[6].to_s,
                                                                                mobile_show_url: csv[7].to_s,
                                                                                pause: @update_status_body[:add_cpc_idea_response][:cpc_idea_types][:pause].to_s,
                                                                                status: @update_status_body[:add_cpc_idea_response][:cpc_idea_types][:status].to_s,
                                                                                active: "0",
                                                                                idea_not_approve_reason: "",
                                                                                mobile_visit_not_approve_reason: "",
                                                                                update_date: @now,                                            
                                                                                create_date: @now })
                                                                          
                                                @db.close                          
                                            else  
                                                update_msg_array << "Row " + row.to_s + " is not added. " + @header[:res_header][:failures][:message].to_s
                                            end
                                            
                                         else
                                            # @logger.info "bulkaddad , no adgroup result found"
                                            update_msg_array << "Row " + row.to_s + " : " + " Adgroup name is invalid. Please try again."
                                         end
                                  end
                                  
                                  
                              end
                            
                              if campaign_type.to_s == "360"
                                
                                    if @remain_quote.to_i <= 500
                                        update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                        return render :text => update_msg_array.join("<br />")
                                    else
                                        db_name = "adgroup_360_"+network_id.to_s
                                        @adgroup = @db[db_name].find('adgroup_name' => csv[0].to_s, 'campaign_id'=> campaign_id.to_i)
                                        @db.close
                                        
                                        if @adgroup.count.to_i > 0
                                            @adgroup.each_with_index do |adgroup, adgroup_index|
                                                temp_adgroup_id = adgroup["adgroup_id"]
                                            end
                                            
                                            requesttypearray = []
                                            request_str = '{"groupId":'+temp_adgroup_id.to_s+',"title":"'+csv[1].to_s+'","description1":"'+csv[2].to_s+'","description2":"'+csv[3].to_s+'","destinationUrl":"'+csv[4].to_s+'","displayUrl":"'+csv[5].to_s+'","mobileDestinationUrl":"'+csv[6].to_s+'","mobileDisplayUrl":"'+csv[7].to_s+'"}'
                                            requesttypearray << request_str
                                            
                                            request = '['+requesttypearray.join(",")+']'
                                                         
                                            body = { 
                                                'creatives' => request
                                            }
                                            
                                            @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "creative", "add", body)
                                            @affectedRecords = @update_res["creative_add_response"]
                                            
                                            # @logger.info @affectedRecords
                                            # @logger.info @update_res
                                            
                                            @remain_quote = @response.headers["quotaremain"].to_i
                                            
                                            if @update_res["creative_add_response"]["failures"].nil?
                                                # update_msg_array << "Row " + row.to_s + " adgroup add to "+temp_network_name.to_s+" Success."
                                                
                                                ad_db_name = "ad_360_"+network_id.to_s
                                                @db[ad_db_name].insert_one({ 
                                                          network_id: network_id.to_i,
                                                          account_id: temp_360_account_id.to_i,
                                                          account_name: temp_network_name.to_s,
                                                          campaign_id: campaign_id.to_i,
                                                          campaign_name: temp_campaign_name.to_s,
                                                          adgroup_id: temp_adgroup_id.to_i,
                                                          ad_id: @update_res["creative_add_response"]["creativeIdList"]["item"].to_i,
                                                          title: csv[1].to_s, 
                                                          description: csv[2].to_s, 
                                                          status: "启用",
                                                          sys_status: "有效",
                                                          show_url: csv[5].to_s,
                                                          visit_url: csv[4].to_s,
                                                          mobile_show_url: csv[7].to_s,
                                                          mobile_visit_url: csv[6].to_s,
                                                          extend_ad_type: 3,
                                                          update_date: @now,                                            
                                                          create_date: @now 
                                                          })
                                                @db.close 
                                                
                                            else
                                                update_msg_array << "Row " + row.to_s + " is not added." + @update_res["group_batchAdd_response"]["failures"]["item"]["message"].to_s
                                            end
                                            
                                        else
                                            update_msg_array << "Row " + row.to_s + " : " + " Adgroup name is invalid. Please try again."
                                        end
                                    end
                                    
                              end
                            
                          end
                      else
                          update_msg_array << "Row " + row.to_s + " : Missing Require Field, Please Check your file."
                      end
                  end
              end  
          end
          
          
          return render :text => update_msg_array.join("<br />")
      rescue Exception
          return render :text => "Ad Channel is busy, please try again a bit later."
      end
      
  end
  
  
  
  
  
  def bulkaddadgroup
    
      begin
          file = params[:file]
          
          campaign_type = params[:campaign_type]
          campaign_id = params[:campaign_id]
          network_id = params[:network_id]
          
          #Adgroup Name(Require)  Max Price(Optional) Pause(Optional)
          # @logger.info "bulkaddadgroup start" 
          
          if campaign_type.to_s == "" || campaign_id.to_s == "" || network_id.to_s == ""
              return render :text => "Your request is invalid. Please try again."
          end
          
          if campaign_type == "threesixty"
              campaign_type = "360"
          end
          
          begin
              xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
          rescue Exception
              return render :text => "File type error, Exexl File(.xlsx) only."
          end
          
          @network = @db[:network].find('id' => network_id.to_i, 'type' => campaign_type.to_s).limit(1)
          @db.close
          
          if @network.count.to_i != 1 
              return render :text => "Your request is invalid. Please try again."
          end
          
          login = 0
          update_msg_array = []
          temp_network_name = ""
          temp_campaign_name = ""
          temp_360_account_id = ""
          
          if campaign_type.to_s == "sogou"
              @campaign = @db["all_campaign"].find('cpc_plan_id' => campaign_id.to_i, 'network_type' => "sogou")  
              @db.close
          end
          
          if campaign_type.to_s == "360"
              @campaign = @db["all_campaign"].find('campaign_id' => campaign_id.to_i, 'network_type' => "360")
              @db.close
          end
          
          if @campaign.count.to_i > 0
              @campaign.each do |campaign_d|
                  temp_campaign_name = campaign_d['campaign_name']
              end
          end
          
          
          if @network.count.to_i > 0
              @network.each do |network_d|
                
                  temp_network_name = network_d["name"].to_s
                  
                  if network_d["type"].to_s == "360"
                    
                      @username = network_d["username"]
                      @password = network_d["password"]
                      @apitoken = network_d["api_token"]
                      @apisecret = network_d["api_secret"]
                      temp_360_account_id = network_d["accountid"]
                      
                      login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                      @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                      
                      if @refresh_token.nil?
                          return render :text => "API Info is invalid, Please Check your API Info and Token is correct in Adeqo."
                      else
                          @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                                                      
                          @remain_quote = @response.headers["quotaremain"].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                          end
                      end
                  end
                  
                  if network_d["type"].to_s == "sogou"
                    
                      sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                      sogou_result = @sogou_api.call(:get_account_info)
                                              
                      if sogou_result.header[:res_header][:desc].to_s == "success"
                          @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                          if @remain_quote.to_i <= 500
                              return render :text => "Account " + network_d["name"] + " doesn't have enough quota."
                          else
                              login = 1
                              sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcGrpService")
                          end
                      else
                          return render :text => "Account " + network_d["name"] + " " + sogou_result.header[:res_header][:failures][:message].to_s
                      end                        
                  end
              end
          end
          # joe
          
          update_msg_array << "Complete.<br />"
          
          if login == 1
          
              xlsx.each_with_index do |csv, csv_index|
                  
                  if csv_index.to_i != 0
                      
                      row = csv_index.to_i + 1
                      
                      if csv[0].to_s != "" && csv[1].to_s != ""
                          
                          if campaign_type.to_s == "sogou"
                              
                              requesttypearray = []
                              requesttype = {}
                              
                              if @remain_quote.to_i <= 500
                                    update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                    return render :text => update_msg_array.join("<br />")
                              else
                                    requesttype[:cpcPlanId]    =  campaign_id
                                    requesttype[:cpcGrpName]    =  csv[0].to_s
                                    requesttype[:maxPrice]    =  csv[1].to_f
                                    
                                    if csv[2].to_s != ""
                                        if csv[2].to_s.downcase == "true"
                                            pause = "true"
                                        else
                                            pause = "false"
                                        end
                                        
                                        requesttype[:pause]    =  pause.to_s.downcase
                                    else
                                        pause = "false"
                                        requesttype[:pause]    =  pause.to_s.downcase
                                    end
                                    
                                    requesttypearray << requesttype
                                    
                                    @update_status = @sogou_api.call(:add_cpc_grp, message: { cpcGrpTypes: requesttypearray })
                                    @header = @update_status.header.to_hash
    
                                    @msg = @header[:res_header][:desc]
                                    @remain_quote = @header[:res_header][:rquota]
                                    # @logger.info @header
                                      
                                    @update_status_body = @update_status.body.to_hash
                                    # # @logger.info @update_status_body
                                    
                                    
                                    if @msg.to_s.downcase == "success"
                                        # update_msg_array << "Row " + row.to_s + " adgroup add to "+temp_network_name.to_s+" Success."
                                        
                                        db_name = "adgroup_sogou_"+network_id.to_s 
                                        @db[db_name].insert_one({ 
                                                                  network_id: network_id.to_i,
                                                                  cpc_plan_id: campaign_id.to_i,
                                                                  cpc_grp_id: @update_status_body[:add_cpc_grp_response][:cpc_grp_types][:cpc_grp_id].to_i,
                                                                  name: @update_status_body[:add_cpc_grp_response][:cpc_grp_types][:cpc_grp_name].to_s,
                                                                  max_price: csv[1].to_f,
                                                                  negative_words: "",
                                                                  exact_negative_words: "",
                                                                  pause: @update_status_body[:add_cpc_grp_response][:cpc_grp_types][:pause].to_s,
                                                                  status: @update_status_body[:add_cpc_grp_response][:cpc_grp_types][:status].to_i,
                                                                  opt: "",
                                                                  update_date: @now,                                            
                                                                  create_date: @now })
                                                                  
                                        @db.close                          
                                    else  
                                        update_msg_array << "Row " + row.to_s + " is not added. " + @header[:res_header][:failures][:message].to_s
                                    end
                              end
                          end
                          
                          
                          
                          
                          if campaign_type.to_s == "360"
                            
                              if @remain_quote.to_i <= 500
                                    update_msg_array << "Terminate at Row " + row.to_s + ". Quota not enough."
                                    return render :text => update_msg_array.join("<br />")
                              else
                                    requesttypearray = []
                                    request_str = '{"campaignId":'+campaign_id+',"name":"'+csv[0].to_s+'","price":'+csv[1].to_s+'}'
                                    requesttypearray << request_str
                                     
                                    #request = '[{"campaignId":868451104,"name":"测试组","price":1,"negativeWords":"{"phrase":["广泛"],"exact":["精确"]}"}]'
                                    
                                    request = '['+requesttypearray.join(",")+']'
                                    # @logger.info request
                                                 
                                    body = { 
                                        'groups' => request
                                    }
                                    
                                    @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "group", "batchAdd", body)
                                    @affectedRecords = @update_res["group_batchAdd_response"]
                                    
                                    # @logger.info @affectedRecords
                                    # @logger.info @update_res
                                    @remain_quote = @response.headers["quotaremain"].to_i
                                    
                                    if @update_res["group_batchAdd_response"]["failures"].nil?
                                        # update_msg_array << "Row " + row.to_s + " adgroup add to "+temp_network_name.to_s+" Success."
                                        
                                        
                                        adgroup_db_name = "adgroup_360_"+network_id.to_s
                                        @db[adgroup_db_name].insert_one({ 
                                                                network_id: network_id.to_i,
                                                                account_id: temp_360_account_id.to_i,
                                                                account_name: temp_network_name.to_s,
                                                                campaign_id: campaign_id.to_i,
                                                                campaign_name: temp_campaign_name.to_s,
                                                                adgroup_id: @update_res["group_batchAdd_response"]["groupIdList"]["item"].to_i,
                                                                adgroup_name: csv[0].to_s,
                                                                price: csv[1].to_f,
                                                                negative_words: "",
                                                                negative_words_mode: "",
                                                                status: "启用",
                                                                sys_status: "有效",
                                                                update_date: @now,                                            
                                                                create_date: @now 
                                                                })
                                        @db.close 
                                        
                                    else
                                        update_msg_array << "Row " + row.to_s + " is not added." + @update_res["group_batchAdd_response"]["failures"]["item"]["message"].to_s
                                    end
                              end
                              
                          end
                      
                      else
                          update_msg_array << "Row " + row.to_s + " : Missing Require Field, Please Check your file."
                      end
                  end
                  
              end
              
          end
          
          
          return render :text => update_msg_array.join("<br />") + "<br /><br />Please refresh to view the latset update."
      rescue Exception
          return render :text => "Ad Channel is busy, please try again a bit later."
      end
      

      # return render :text => 'true' 
  end
  
  
  
  def bulkeditcampaign
    
      # @logger.info "bulkeditcampaign start"
      
      file = params[:edit_file]
      
      
      # # @logger.info file.original_filename
      
      begin
          xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      rescue Exception
          return render :text => "File type error, Exexl File(.xlsx) only."
      end
      
      
      temp_network_name = ""
      temp_network_type = ""
      temp_network_id = ""
      
      temp_360_account_id = ""
      login = 0
      
      return render :text => "Bulk Edit is in maintenance, Please try again."
  end
  
  def bulkaddcampaign
    
      #Account Name(Require) Campaign Name(Require)  Daily Budget(Optional)  Negative Words(Optional)  Exact Negative Words(Optional)  Pause(Optional)
      # @logger.info "bulkaddcampaign start" 
      file = params[:file]
      
      @test = 0
      update_msg_array = []
      
      begin
          xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      rescue Exception
          return render :text => "File type error, Exexl File(.xlsx) only."
      end
      
      temp_network_name = ""
      temp_network_type = ""
      temp_network_id = ""
      
      temp_360_account_id = ""
      login = 0
      
      begin
          xlsx.each_with_index do |csv, csv_index|
            
              if csv_index.to_i != 0
                
                  row = csv_index.to_i + 1
                  
                  if csv[0].to_s == ""
                      update_msg_array << "Row " + row + " : Account Name is invalid, Please Check your file."
                  elsif csv[1].to_s == ""
                      update_msg_array << "Row " + row + " : Campaign Name is invalid, Please Check your file."
                  else
                      if csv[0].to_s != temp_network_name
                          @network = @db[:network].find('name' => csv[0].to_s)
                          @db.close
                      
                          if @network.count.to_i < 0 
                              update_msg_array << "Row " + row.to_s + " : Account Name is invalid, Please Check your file."
                          else
                              @network.each do |network_d|
                                 
                                 temp_network_name = csv[0]
                                 temp_network_type = network_d["type"].to_s
                                 temp_network_id = network_d["id"].to_i
                                 
                                 if network_d["type"].to_s == "360"
                                      @username = network_d["username"]
                                      @password = network_d["password"]
                                      @apitoken = network_d["api_token"]
                                      @apisecret = network_d["api_secret"]
                                      
                                      temp_360_account_id = network_d["accountid"]
                                      
                                      login_info = threesixty_api_login(@username,@password,@apitoken,@apisecret)
                                      @refresh_token = login_info["account_clientLogin_response"]["accessToken"]
                                      
                                      if !@refresh_token.nil?
                                          login = 1
                                          @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "account", "getInfo")
                                          
                                          @remain_quote = @response.headers["quotaremain"].to_i
                                          if @remain_quote.to_i <= 500
                                              update_msg_array << "Row " + row.to_s + " : 360 Account " + network_d["name"] + " doesn't have enough quota."
                                          end
                                      else
                                          login = 0
                                          @remain_quote = 0
                                          update_msg_array << "Row " + row.to_s + " : 360 Account " + network_d["name"].to_s + " " + login_info["account_clientLogin_response"]["failures"]["item"]["message"].to_s
                                      end
                                  end
                                  
                                  if network_d["type"].to_s == "sogou"
                                      sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"AccountService")
                                      sogou_result = @sogou_api.call(:get_account_info)
                                      
                                      if sogou_result.header[:res_header][:desc].to_s == "success"
                                          login = 1
                                          @remain_quote = sogou_result.header[:res_header][:rquota].to_i
                                          if @remain_quote.to_i <= 500
                                              update_msg_array << "Row " + row.to_s + " : Sogou Account " + network_d["name"] + " doesn't have enough quota."
                                          else
                                              sogou_api(network_d["username"],network_d["password"],network_d["api_token"],"CpcPlanService")
                                          end
                                      else
                                          login = 0
                                          @remain_quote = 0
                                          update_msg_array << "Row " + row.to_s + " : Sogou Account " + network_d["name"].to_s + " " + sogou_result.header[:res_header][:failures][:message].to_s
                                      end
                                  end
                              end
                          end
                      end
                      
                      
                      
                      if login == 1
                        
                          if temp_network_type == "sogou"
                              if @remain_quote.to_i <= 500
                                  update_msg_array << "Row " + row.to_s + " is not updated. Quota not enough."
                              else
                              
                                  requesttypearray = []
                                  requesttype = {}
                                                
                                  requesttype[:cpcPlanName]    =  csv[1].to_s
                                  
                                  if csv[2].to_f > 0
                                      requesttype[:budget]    =  csv[2].to_i
                                  end
                                  
                                  if csv[3].to_s != ""
                                      requesttype[:negativeWords]    =  csv[3].to_s.gsub('"', '').gsub(',', ' ')
                                  end
                                  
                                  if csv[4].to_s != ""
                                      requesttype[:exactNegativeWords]    =  csv[4].to_s.gsub('"', '').gsub(',', ' ')
                                  end
                                  
                                  if csv[5].to_s != ""
                                      if csv[5].to_s.downcase == "false"
                                          pause = "false"
                                      else
                                          pause = "true"
                                      end
                                      
                                      requesttype[:pause]    =  pause.to_s.downcase
                                  else
                                      pause = "true"
                                      requesttype[:pause]    =  "true"
                                  end
                                  
                                  requesttypearray << requesttype
                                  
                                  
                                  @update_status = @sogou_api.call(:add_cpc_plan, message: { cpcPlanTypes: requesttypearray })
                                  
                                  @header = @update_status.header.to_hash
                                  @msg = @header[:res_header][:desc]
                                  @remain_quote = @header[:res_header][:rquota]
                                  # @logger.info @header
                                  
                                  @update_status_body = @update_status.body.to_hash
                                  # # @logger.info @update_status_body
                                  
                                  if @msg.to_s.downcase == "success"
                                      # update_msg_array << "Row " + row.to_s + " campaign add to "+temp_network_name.to_s+" Success." 
                                      
                                      @db["all_campaign"].insert_one({ 
                                                                      network_id: temp_network_id.to_i,
                                                                      network_type: "sogou", 
                                                                      cpc_plan_id: @update_status_body[:add_cpc_plan_response][:cpc_plan_types][:cpc_plan_id].to_i,
                                                                      campaign_name: @update_status_body[:add_cpc_plan_response][:cpc_plan_types][:cpc_plan_name].to_s, 
                                                                      budget: csv[2].to_f, 
                                                                      regions: nil, 
                                                                      exclude_ips: "",
                                                                      negative_words: csv[3].to_s.gsub('"', '').to_s,
                                                                      exact_negative_words: csv[4].to_s.gsub('"', '').to_s,
                                                                      schedule: "",
                                                                      budget_offline_time: "",
                                                                      show_prob: "",
                                                                      pause: pause.to_s,
                                                                      join_union: @update_status_body[:add_cpc_plan_response][:cpc_plan_types][:join_union].to_s,
                                                                      union_price: nil,
                                                                      status: @update_status_body[:add_cpc_plan_response][:cpc_plan_types][:status].to_i,
                                                                      mobile_price_rate: @update_status_body[:add_cpc_plan_response][:cpc_plan_types][:mobile_price_rate].to_s,
                                                                      opt: nil,
                                                                      update_date: @now,                                            
                                                                      create_date: @now })
                                      @db.close
                                  else  
                                      update_msg_array << "Row " + row.to_s + " is not added. " + @header[:res_header][:failures][:message].to_s
                                  end
                              end
                          end
                          
                          
                          
                          
                          if temp_network_type == "360"
                              if @remain_quote.to_i <= 500
                                  update_msg_array << "Row " + row.to_s + " is not updated. Quota not enough."
                              else
                                  body = {}
                                  body[:name] = csv[1].to_s
                                  
                                  if csv[2].to_f > 0
                                      body[:budget] =  csv[2].to_f
                                  end
                                       
                                  body[:negativeWords] = '{"phrase":['+csv[3].to_s+'],"exact":['+csv[4].to_s+']}'                              
                                  
                                  db_status = "暂停"
                                                                                                            
                                  if csv[5].to_s != ""
                                      if csv[5].to_s.downcase == "false"
                                          status_360 = "enable"
                                          db_status = "启用"
                                      else
                                          status_360 = "pause"
                                          db_status = "暂停"
                                      end
                                    
                                      body[:status] =  status_360
                                  else
                                    
                                      status_360 = "pause"
                                      db_status = "暂停"
                                      
                                      body[:status] =  status_360
                                  end
                                   
                                  if csv[6].to_s != ""
                                      body[:startDate] =  csv[6].to_s
                                  end
                                  
                                  if csv[7].to_s != ""
                                      body[:endDate] =  csv[7].to_s
                                  end
                                  
                                  @update_res = threesixty_api( @apitoken.to_s, @refresh_token, "campaign", "add", body)
                                  @affectedRecords = @update_res["campaign_add_response"]
                                  
                                  @remain_quote = @response.headers["quotaremain"].to_i
                                  
                                  # @logger.info "---"
                                  # @logger.info body
                                  # # @logger.info @affectedRecords
                                  # @logger.info @update_res
                                  
                                  
                                  if @update_res["campaign_add_response"]["failures"].nil?
                                      # update_msg_array << "Row " + row.to_s + " campaign add to "+temp_network_name.to_s+" Success."
                                      
                                      @db["all_campaign"].insert_one({ 
                                                          network_id: temp_network_id.to_i,
                                                          network_type: "360", 
                                                          account_id: temp_360_account_id.to_i,
                                                          account_name: temp_network_name.to_s,
                                                          campaign_id: @update_res["campaign_add_response"]["id"].to_i,
                                                          campaign_name: csv[1].to_s, 
                                                          budget: csv[2].to_f, 
                                                          regions: "全国", 
                                                          schedule: "",
                                                          start_date: csv[6].to_s,
                                                          end_date: csv[7].to_s,
                                                          status: db_status.to_s,
                                                          sys_status: "有效",
                                                          extend_ad_type: 1,
                                                          mobile_price_rate: 100,
                                                          
                                                          negative_words: csv[3].to_s.gsub('"', '').to_s,
                                                          exact_negative_words: csv[4].to_s.gsub('"', '').to_s,
                                                          
                                                          update_date: @now.to_s,                                            
                                                          create_date: @now.to_s 
                                                        })
                                      @db.close 
                                      
                                  else
                                      update_msg_array << "Row " + row.to_s + " is not added." + @update_res["campaign_add_response"]["failures"]["item"]["message"].to_s
                                  end
                                  
                              end
                          end
                      end
                      
                      
                  end
                  
              end 
          end
    
          # xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
     
          # xlsx.each_with_pagename do |name, sheet|
              # @data << sheet.row
          # end
          
          # data = {:message => @test, :status => "false"}
          # return render :json => data, :status => :ok
          return render :text => "Complete.<br /><br />" + update_msg_array.join("<br />")
      
      rescue Exception
          return render :text => "Ad Channel is busy, please try again a bit later."
      end
  end
  
  
  def index
    @current_user_network = @db[:network].find('company_id' => @user_company_id)
    @db.close
  end

end
