class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  protect_from_forgery :except => :form_csv
  skip_before_action :verify_authenticity_token
  before_action :now, :db, :logger, :defaultdayrange, :html_title
  require 'geoip'
  require 'geo_location'
  require 'active_support'
  require 'csv'
  require 'httparty'
  
  require 'roo'
  
  require 'net/http'
  require 'mailgun'
  
  require 'open-uri'
  require 'json'
  
  def html_title
      @title = " | The #1 Chinese Search Engine Cross-Channel Advertising Platform"
  end
  
  def not_found
      render :status => 404
  end
  
  
  
  
  def exporteventfile
      # begin
      @logger.info "export event file"
      @one_hour_ago = Time.now - 1.hours

      name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H")
      @one_hour_ago = @one_hour_ago.to_s + ":00:00 CST"
      
      # total_events = @db2["events"].find('date' => { '$gte' => @one_hour_ago.to_s })
      total_events = @db2["events"].find({ "$and" => [{:random_number => { '$ne' => nil }} ] })
      @db2.close
      
      name = "export_event_"+name_datetime.to_s
      del_event_array = []
      
      if total_events.no_cursor_timeout.count.to_i > 0
        
          event_array = []
          all_event_hash = {}
          
          total_events.each do |total_events_d|
            
              del_event_array << total_events_d["id"]
              
              array = []
              
              array << total_events_d["id"]
              array << total_events_d["random_number"]
              array << total_events_d["session_id"]
              array << total_events_d["tag_version"]
              array << total_events_d["company_id"]
              array << total_events_d["referer"]
              array << total_events_d["ip"]
              array << total_events_d["country"]
              array << total_events_d["city"]
              array << total_events_d["variant"]
              array << total_events_d["user_agent"]
              array << total_events_d["cookies"]
              array << total_events_d["other_param"]
              array << total_events_d["date"]
              array << total_events_d["check_status"]
              
              event_array << array
              
              
              # this part is for different company
              if all_event_hash[total_events_d["company_id"]].nil?
                all_event_hash[total_events_d["company_id"]] = []
              end
              
              all_event_hash[total_events_d["company_id"]] << array
              
          end
      
          p = Axlsx::Package.new
          wb = p.workbook
            
          wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               event_array.each_with_index do |csv, csv_index|
                  sheet.add_row csv
               end
          end
           
          create_excel_path = '/home/bmg/adeqo/public/export_event/'+name+'.xlsx'
          p.serialize(create_excel_path)
          
          
          if all_event_hash.count.to_i > 0
              all_event_hash.each do |key, value|
                
                  p = Axlsx::Package.new
                  wb = p.workbook
                    
                  wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       value.each_with_index do |csv, csv_index|
                          sheet.add_row csv
                       end
                  end
                
                  create_excel_path = '/home/bmg/adeqo/public/export_event/company_id_'+key.to_s+'_'+name+'.xlsx'
                  p.serialize(create_excel_path)
              end
          end
          
      end
       
      @db2["events"].find('id' => { "$in" => del_event_array}).delete_many
      @db2.close()

      
      # normmal event table start
      total_events = @db2["events"].find({ "$and" => [{:random_number => { '$eq' => nil }} ] })
      @db2.close
      
      name = "export_n_event_"+name_datetime.to_s
      del_event_array = []
      
      if total_events.no_cursor_timeout.count.to_i > 0
        
          event_array = []
          all_event_hash = {}
          
          total_events.each do |total_events_d|
            
              del_event_array << total_events_d["_id"]
              
              array = []
                
              array << total_events_d["type"]
              array << total_events_d["user_id"]
              array << total_events_d["cookie_id"]
              
              array << total_events_d["tag_version"]
              array << total_events_d["company_id"]
              array << total_events_d["host"]
              array << total_events_d["referer"]
              array << total_events_d["current_page"]
              
              array << total_events_d["ip"]
              array << total_events_d["country"]
              array << total_events_d["city"]
              array << total_events_d["variant"]
              array << total_events_d["user_agent"]
              
              array << total_events_d["category"]
              array << total_events_d["action"]
              array << total_events_d["label"]
              array << total_events_d["value"]
              
              array << total_events_d["order_id"]
              array << total_events_d["promotecode"]
              array << total_events_d["confirmation_category"]
              array << total_events_d["price"]
              array << total_events_d["revenue"]
              array << total_events_d["confirmation_name"]
              array << total_events_d["sku"]
              array << total_events_d["quantity"]
              
              array << total_events_d["cookies"]
              array << total_events_d["other_param"]
              array << total_events_d["check_time_status"]
              array << total_events_d["check_event_status"]
              array << total_events_d["check_page_count_status"]
              array << total_events_d["check_url_status"]
              array << total_events_d["check_confirmation_status"]
              array << total_events_d["check_status"]
              array << total_events_d["date"]
              
              event_array << array
              
              # this part is for different company
              if all_event_hash[total_events_d["company_id"]].nil?
                all_event_hash[total_events_d["company_id"]] = []
              end
              
              all_event_hash[total_events_d["company_id"]] << array
              
          end
      
          p = Axlsx::Package.new
          wb = p.workbook
            
          wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               event_array.each_with_index do |csv, csv_index|
                  sheet.add_row csv
               end
          end
           
          create_excel_path = '/home/bmg/adeqo/public/export_event/'+name+'.xlsx'
          p.serialize(create_excel_path)
          
          
          if all_event_hash.count.to_i > 0
              all_event_hash.each do |key, value|
                
                  p = Axlsx::Package.new
                  wb = p.workbook
                    
                  wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       value.each_with_index do |csv, csv_index|
                          sheet.add_row csv
                       end
                  end
                
                  create_excel_path = '/home/bmg/adeqo/public/export_event/n_company_id_'+key.to_s+'_'+name+'.xlsx'
                  p.serialize(create_excel_path)
              end
          end
          
      end
       
      @db2["events"].find('_id' => { "$in" => del_event_array}).delete_many
      @db2.close()
      
      
      # rescue Exception
      # end
      
      @logger.info "export event file done"
      data = {:export_event => total_events.count.to_i, :export_event_time => @one_hour_ago, :del_event_array => del_event_array.count.to_i, :status => "true"}
      return render :json => data, :status => :ok
      
  end
  
  
  
  
  # def exporteventfile
      # begin
      # @logger.info "export event file"
      # @one_hour_ago = Time.now - 1.hours
# 
      # name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      # # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H")
      # @one_hour_ago = @one_hour_ago.to_s + ":00:00 CST"
#       
      # # total_events = @db2["events"].find('date' => { '$gte' => @one_hour_ago.to_s })
      # total_events = @db2["events"].find()
      # @db2.close
#       
      # name = "export_event_"+name_datetime.to_s
      # del_event_array = []
#       
      # if total_events.no_cursor_timeout.count.to_i > 0
#         
          # event_array = []
          # all_event_hash = {}
#           
          # total_events.each do |total_events_d|
#             
              # del_event_array << total_events_d["id"]
#               
              # array = []
#               
              # array << total_events_d["id"]
              # array << total_events_d["random_number"]
              # array << total_events_d["session_id"]
              # array << total_events_d["tag_version"]
              # array << total_events_d["company_id"]
              # array << total_events_d["referer"]
              # array << total_events_d["ip"]
              # array << total_events_d["country"]
              # array << total_events_d["city"]
              # array << total_events_d["variant"]
              # array << total_events_d["user_agent"]
              # array << total_events_d["cookies"]
              # array << total_events_d["other_param"]
              # array << total_events_d["date"]
              # array << total_events_d["check_status"]
#               
              # event_array << array
#               
#               
              # # this part is for different company
              # if all_event_hash[total_events_d["company_id"]].nil?
                # all_event_hash[total_events_d["company_id"]] = []
              # end
#               
              # all_event_hash[total_events_d["company_id"]] << array
#               
          # end
#       
          # p = Axlsx::Package.new
          # wb = p.workbook
#             
          # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               # event_array.each_with_index do |csv, csv_index|
                  # sheet.add_row csv
               # end
          # end
#            
          # create_excel_path = '/home/bmg/adeqo/public/export_event/'+name+'.xlsx'
          # p.serialize(create_excel_path)
#           
#           
          # if all_event_hash.count.to_i > 0
              # all_event_hash.each do |key, value|
#                 
                  # p = Axlsx::Package.new
                  # wb = p.workbook
#                     
                  # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       # value.each_with_index do |csv, csv_index|
                          # sheet.add_row csv
                       # end
                  # end
#                 
                  # create_excel_path = '/home/bmg/adeqo/public/export_event/company_id_'+key.to_s+'_'+name+'.xlsx'
                  # p.serialize(create_excel_path)
              # end
          # end
#           
      # end
#        
      # @db2["events"].find('id' => { "$in" => del_event_array}).delete_many
      # @db2.close()
#       
#       
#       
      # # normmal event table start
      # total_events = @db2["n_events"].find()
      # @db2.close
#       
      # name = "export_n_event_"+name_datetime.to_s
      # del_event_array = []
#       
      # if total_events.no_cursor_timeout.count.to_i > 0
#         
          # event_array = []
          # all_event_hash = {}
#           
          # total_events.each do |total_events_d|
#             
              # del_event_array << total_events_d["_id"]
#               
              # array = []
#               
              # if total_events_d["type"].to_s == "event_goal"
#                 
                  # array << total_events_d["type"]
                  # array << total_events_d["user_id"]
                  # array << total_events_d["cookie_id"]
#                   
                  # array << total_events_d["tag_version"]
                  # array << total_events_d["company_id"]
                  # array << total_events_d["host"]
                  # array << total_events_d["referer"]
                  # array << total_events_d["current_page"]
#                   
                  # array << total_events_d["ip"]
                  # array << total_events_d["country"]
                  # array << total_events_d["city"]
                  # array << total_events_d["variant"]
                  # array << total_events_d["user_agent"]
#                   
                  # array << total_events_d["category"]
                  # array << total_events_d["action"]
                  # array << total_events_d["label"]
                  # array << total_events_d["value"]
#                   
                  # array << total_events_d["cookies"]
                  # array << total_events_d["other_param"]
                  # array << total_events_d["check_time_status"]
                  # array << total_events_d["check_event_status"]
                  # array << total_events_d["check_page_count_status"]
                  # array << total_events_d["check_url_status"]
                  # array << total_events_d["check_confirmation_status"]
                  # array << total_events_d["check_status"]
                  # array << total_events_d["date"]
#                 
#                 
              # elsif total_events_d["type"].to_s == "confirmation"
#                 
                  # array << total_events_d["type"]
                  # array << total_events_d["user_id"]
                  # array << total_events_d["cookie_id"]
#                   
                  # array << total_events_d["tag_version"]
                  # array << total_events_d["company_id"]
                  # array << total_events_d["host"]
                  # array << total_events_d["referer"]
                  # array << total_events_d["current_page"]
                  # array << total_events_d["ip"]
                  # array << total_events_d["country"]
                  # array << total_events_d["city"]
                  # array << total_events_d["variant"]
                  # array << total_events_d["user_agent"]
#                   
                  # array << total_events_d["order_id"]
                  # array << total_events_d["promotecode"]
                  # array << total_events_d["confirmation_category"]
                  # array << total_events_d["price"]
                  # array << total_events_d["revenue"]
                  # array << total_events_d["confirmation_name"]
                  # array << total_events_d["sku"]
                  # array << total_events_d["quantity"]
#                   
                  # array << total_events_d["cookies"]
                  # array << total_events_d["other_param"]
                  # array << total_events_d["check_time_status"]
                  # array << total_events_d["check_event_status"]
                  # array << total_events_d["check_page_count_status"]
                  # array << total_events_d["check_url_status"]
                  # array << total_events_d["check_confirmation_status"]
                  # array << total_events_d["check_status"]
                  # array << total_events_d["date"]
#                                             
              # elsif total_events_d["type"].to_s == "other_goal"
                  # array << total_events_d["type"]
                  # array << total_events_d["user_id"]
                  # array << total_events_d["cookie_id"]
#                   
                  # array << total_events_d["tag_version"]
                  # array << total_events_d["company_id"]
                  # array << total_events_d["host"]
                  # array << total_events_d["referer"]
                  # array << total_events_d["current_page"]
                  # array << total_events_d["ip"]
                  # array << total_events_d["country"]
                  # array << total_events_d["city"]
                  # array << total_events_d["variant"]
                  # array << total_events_d["user_agent"]
                  # array << total_events_d["cookies"]
                  # array << total_events_d["other_param"]
                  # array << total_events_d["check_time_status"]
                  # array << total_events_d["check_event_status"]
                  # array << total_events_d["check_page_count_status"]
                  # array << total_events_d["check_url_status"]
                  # array << total_events_d["check_confirmation_status"]
                  # array << total_events_d["check_status"]
                  # array << total_events_d["date"]
              # end 
#                 
#               
              # event_array << array
#               
#               
              # # this part is for different company
              # if all_event_hash[total_events_d["company_id"]].nil?
                # all_event_hash[total_events_d["company_id"]] = []
              # end
#               
              # all_event_hash[total_events_d["company_id"]] << array
#               
          # end
#       
          # p = Axlsx::Package.new
          # wb = p.workbook
#             
          # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               # event_array.each_with_index do |csv, csv_index|
                  # sheet.add_row csv
               # end
          # end
#            
          # create_excel_path = '/home/bmg/adeqo/public/export_event/'+name+'.xlsx'
          # p.serialize(create_excel_path)
#           
#           
          # if all_event_hash.count.to_i > 0
              # all_event_hash.each do |key, value|
#                 
                  # p = Axlsx::Package.new
                  # wb = p.workbook
#                     
                  # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       # value.each_with_index do |csv, csv_index|
                          # sheet.add_row csv
                       # end
                  # end
#                 
                  # create_excel_path = '/home/bmg/adeqo/public/export_event/n_company_id_'+key.to_s+'_'+name+'.xlsx'
                  # p.serialize(create_excel_path)
              # end
          # end
#           
      # end
#        
      # @db2["n_events"].find('_id' => { "$in" => del_event_array}).delete_many
      # @db2.close()
#       
#       
      # rescue Exception
      # end
#       
      # @logger.info "export event file done"
      # data = {:export_event => total_events.count.to_i, :export_event_time => @one_hour_ago, :del_event_array => del_event_array.count.to_i, :status => "true"}
      # return render :json => data, :status => :ok
#       
  # end
  
  def cleaneventfile
      begin
      @logger.info "clean event file"
      @all_event_files = Dir.glob('/home/bmg/adeqo/public/export_event/*')
      
      file_year = (Time.now - 1.day).to_date.strftime("%Y")
      file_month = (Time.now - 1.day).to_date.strftime("%m")
      file_day = (Time.now - 1.day).to_date.strftime("%d")
       
      file_date = file_year + "-" + file_month + "-" + file_day
      
      @all_event_files.each do |all_files_p|
          if all_files_p.to_s.include?(file_date) && !all_files_p.to_s.include?("company")
              File.delete(all_files_p) if File.exist?(all_files_p)
          end
      end
      rescue Exception
      end
      data = {:message => "clean event file", :clean_day => file_date, :status => "true"}
      return render :json => data, :status => :ok
    
  end
  
  def geteventfile
      begin
      @one_hour_ago = Time.now - 1.hours
      name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      
      domain_name = "http://china.adeqo.com:83/export_event/"      
      name = domain_name + "export_event_" + name_datetime + ".xlsx"
      
      download_name = "/home/bmg/adeqo/public/export_event/export_event_"+ name_datetime + ".xlsx"
      
      IO.copy_stream(open(name) , download_name)
      
      tmp_file_path = download_name

                    
      xlsx = Roo::Spreadsheet.open(tmp_file_path, extension: :xlsx)
      xlsx.each_with_index do |csv, csv_index|
         
          cookies_hash = {}
          csv_cookies_array = []
          
          if csv[11].to_s != "{}"
              csv_cookies_array = csv[11].to_s.gsub('{', '').gsub('}', '').split(",")
              
              csv_cookies_array.each do |csv_cookies_array_d|
                  temp_arr = csv_cookies_array_d.split("=>")
                  
                  if !temp_arr[0].nil?
                      name = temp_arr[0].gsub('"', '')
                  end
                  
                  if !temp_arr[1].nil?
                      value = temp_arr[1].gsub('"', '')
                  else
                      value = ""
                  end
                  
                  if !temp_arr[0].nil?
                      cookies_hash[name] = value
                  end
                  
                  cookies_hash[name] = value
              end
              
          end
          
          
          @db2[:events].insert_one({ 
                              id: csv[0].to_s, 
                              random_number: csv[1].to_i.to_s,
                              session_id: csv[2].to_s,
                              tag_version: csv[3].to_s,
                              company_id: csv[4].to_i,
                              referer: csv[5].to_s,
                              ip: csv[6],
                              country: csv[7].to_s,
                              city: csv[8].to_s,
                              variant: csv[9].to_s,
                              user_agent: csv[10].to_s,
                              cookies: cookies_hash,
                              other_param: JSON.parse(csv[12]),
                              date: csv[13].to_s,
                              check_status: csv[14].to_i
                            })
          @db2.close 
          
          @all_event_files = Dir.glob('/home/bmg/adeqo/public/export_event/*')
          
          
      end                    
      rescue Exception
      end 
      
      @all_event_files.each do |all_files_p|
          if all_files_p.to_s.include?(name_datetime)
              File.delete(all_files_p) if File.exist?(all_files_p)
          end
      end
                   
      data = {:message => "get and insert event", :clean_day => name_datetime, :status => "true"}
      return render :json => data, :status => :ok
      
      
  end
  
  
  
  
  def exportclickfile
      # begin
      @logger.info "export click file"
      @one_hour_ago = Time.now - 1.hours

      name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H")
      @one_hour_ago = @one_hour_ago.to_s + ":00:00 CST"
      
      # total_clicks = @db2["clicks"].find('date' => { '$gte' => @one_hour_ago.to_s })
      total_clicks = @db2["clicks"].find({ "$and" => [{:random_number => { '$ne' => nil }} ] })
      @db2.close
      
      name = "export_click_"+name_datetime.to_s
      del_click_array = []
      
      if total_clicks.count.to_i > 0
          
          click_array = []
          all_click_hash = {}
          
          total_clicks.each do |total_clicks_d|
            
              del_click_array << total_clicks_d["id"]
               
              array = []
                
              # this is for the old one
              array << total_clicks_d["id"]
              array << total_clicks_d["random_number"]
              array << total_clicks_d["session_id"]
              array << total_clicks_d["company_id"]
              array << total_clicks_d["network_id"]
              array << total_clicks_d["network_type"]
              array << total_clicks_d["campaign_id"]
              array << total_clicks_d["adgroup_id"]
              array << total_clicks_d["keyword_id"]
              array << total_clicks_d["ad_id"]
              array << total_clicks_d["target_id"]
              array << total_clicks_d["search_q"]
              array << total_clicks_d["ip"]
              array << total_clicks_d["country"]
              array << total_clicks_d["city"]
              array << total_clicks_d["variant"]
              array << total_clicks_d["user_agent"]
              array << total_clicks_d["device"]
              array << total_clicks_d["cookies"]
              array << total_clicks_d["date"]
              array << total_clicks_d["referer"]
              array << total_clicks_d["destination_url"]
                  
              click_array << array
              
              # this part is for different company
              if all_click_hash[total_clicks_d["company_id"]].nil?
                all_click_hash[total_clicks_d["company_id"]] = []
              end
              
              all_click_hash[total_clicks_d["company_id"]] << array
              
          end
        
          p = Axlsx::Package.new
          wb = p.workbook
            
          wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               click_array.each_with_index do |csv, csv_index|
                  begin
                  sheet.add_row csv
                  rescue Exception
                  end
               end
          end
          
          create_excel_path = '/home/bmg/adeqo/public/export_click/'+name+'.xlsx'
          p.serialize(create_excel_path)
          
          
          if all_click_hash.count.to_i > 0
              all_click_hash.each do |key, value|
                
                  p = Axlsx::Package.new
                  wb = p.workbook
                    
                  wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       value.each_with_index do |csv, csv_index|
                          begin
                          sheet.add_row csv
                          rescue Exception
                          end
                       end
                  end
                
                  create_excel_path = '/home/bmg/adeqo/public/export_click/company_id_'+key.to_s+'_'+name+'.xlsx'
                  p.serialize(create_excel_path)
              end
          end
      end
      
      
      @db2["clicks"].find('id' => { "$in" => del_click_array}).delete_many
      @db2.close()
      
      
      # normal clicks sstart here
      total_clicks = @db2["clicks"].find({ "$and" => [{:random_number => { '$eq' => nil }} ] })
      @db2.close
      
      name = "export_n_click_"+name_datetime.to_s
      del_click_array = []
      
      
      # data = {:message => total_clicks, :status => "false"}
      # return render :json => data, :status => :ok
      
      
      if total_clicks.count.to_i > 0
          
          click_array = []
          all_click_hash = {}
          
          total_clicks.each do |total_clicks_d|
            
              del_click_array << total_clicks_d["_id"]
               
              array = []
              array << total_clicks_d["user_id"]
              array << total_clicks_d["cookie_id"]
              array << total_clicks_d["company_id"]
              array << total_clicks_d["network_id"]
              array << total_clicks_d["network_type"]
              array << total_clicks_d["campaign_id"]
              array << total_clicks_d["adgroup_id"]
              array << total_clicks_d["keyword_id"]
              array << total_clicks_d["ad_id"]
              array << total_clicks_d["search_q"]
              array << total_clicks_d["ip"]
              array << total_clicks_d["country"]
              array << total_clicks_d["city"]
              array << total_clicks_d["variant"]
              array << total_clicks_d["user_agent"]
              array << total_clicks_d["device"]
              array << total_clicks_d["cookies"]
              array << total_clicks_d["date"]
              array << total_clicks_d["referer"]
              array << total_clicks_d["destination_url"]
              array << total_clicks_d["check_time_status"]
              array << total_clicks_d["check_event_status"]
              array << total_clicks_d["check_page_count_status"]
              array << total_clicks_d["check_url_status"]
              array << total_clicks_d["check_confirmation_status"]
              
              
              click_array << array
              
              # this part is for different company
              if all_click_hash[total_clicks_d["company_id"]].nil?
                all_click_hash[total_clicks_d["company_id"]] = []
              end
              
              all_click_hash[total_clicks_d["company_id"]] << array
              
          end
        
          p = Axlsx::Package.new
          wb = p.workbook
            
          wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               click_array.each_with_index do |csv, csv_index|
                  begin
                  sheet.add_row csv
                  rescue Exception
                  end
               end
          end
          
          create_excel_path = '/home/bmg/adeqo/public/export_click/'+name+'.xlsx'
          p.serialize(create_excel_path)
          
          
          if all_click_hash.count.to_i > 0
              all_click_hash.each do |key, value|
                
                  p = Axlsx::Package.new
                  wb = p.workbook
                    
                  wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       value.each_with_index do |csv, csv_index|
                          begin
                          sheet.add_row csv
                          rescue Exception
                          end
                       end
                  end
                
                  create_excel_path = '/home/bmg/adeqo/public/export_click/n_company_id_'+key.to_s+'_'+name+'.xlsx'
                  p.serialize(create_excel_path)
              end
          end
      end
      
      
      @db2["clicks"].find('_id' => { "$in" => del_click_array}).delete_many
      @db2.close()
      
      
      
      # rescue Exception
      # end
      
      @logger.info "export click file done"
      data = {:export_click => total_clicks.count.to_i, :export_click_time => @one_hour_ago, :total_del_clicks => del_click_array.count.to_i, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  
  # def exportclickfile
      # # begin
      # @logger.info "export click file"
      # @one_hour_ago = Time.now - 1.hours
# 
      # name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      # # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
      # @one_hour_ago = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d %H")
      # @one_hour_ago = @one_hour_ago.to_s + ":00:00 CST"
#       
      # # total_clicks = @db2["clicks"].find('date' => { '$gte' => @one_hour_ago.to_s })
      # total_clicks = @db2["clicks"].find()
      # @db2.close
#       
      # name = "export_click_"+name_datetime.to_s
      # del_click_array = []
#       
      # if total_clicks.count.to_i > 0
#           
          # click_array = []
          # all_click_hash = {}
#           
          # total_clicks.each do |total_clicks_d|
#             
              # del_click_array << total_clicks_d["id"]
#                
              # array = []
              # array << total_clicks_d["id"]
              # array << total_clicks_d["random_number"]
              # array << total_clicks_d["session_id"]
              # array << total_clicks_d["company_id"]
              # array << total_clicks_d["network_id"]
              # array << total_clicks_d["network_type"]
              # array << total_clicks_d["campaign_id"]
              # array << total_clicks_d["adgroup_id"]
              # array << total_clicks_d["keyword_id"]
              # array << total_clicks_d["ad_id"]
              # array << total_clicks_d["target_id"]
              # array << total_clicks_d["search_q"]
              # array << total_clicks_d["ip"]
              # array << total_clicks_d["country"]
              # array << total_clicks_d["city"]
              # array << total_clicks_d["variant"]
              # array << total_clicks_d["user_agent"]
              # array << total_clicks_d["device"]
              # array << total_clicks_d["cookies"]
              # array << total_clicks_d["other_parameters"]
              # array << total_clicks_d["date"]
              # array << total_clicks_d["referer"]
              # array << total_clicks_d["destination_url"]
#               
              # click_array << array
#               
              # # this part is for different company
              # if all_click_hash[total_clicks_d["company_id"]].nil?
                # all_click_hash[total_clicks_d["company_id"]] = []
              # end
#               
              # all_click_hash[total_clicks_d["company_id"]] << array
#               
          # end
#         
          # p = Axlsx::Package.new
          # wb = p.workbook
#             
          # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               # click_array.each_with_index do |csv, csv_index|
                  # begin
                  # sheet.add_row csv
                  # rescue Exception
                  # end
               # end
          # end
#           
          # create_excel_path = '/home/bmg/adeqo/public/export_click/'+name+'.xlsx'
          # p.serialize(create_excel_path)
#           
#           
          # if all_click_hash.count.to_i > 0
              # all_click_hash.each do |key, value|
#                 
                  # p = Axlsx::Package.new
                  # wb = p.workbook
#                     
                  # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       # value.each_with_index do |csv, csv_index|
                          # begin
                          # sheet.add_row csv
                          # rescue Exception
                          # end
                       # end
                  # end
#                 
                  # create_excel_path = '/home/bmg/adeqo/public/export_click/company_id_'+key.to_s+'_'+name+'.xlsx'
                  # p.serialize(create_excel_path)
              # end
          # end
      # end
#       
#       
      # @db2["clicks"].find('id' => { "$in" => del_click_array}).delete_many
      # @db2.close()
#       
#       
#       
#       
#       
      # # normal clicks sstart here
      # total_clicks = @db2["n_clicks"].find()
      # @db2.close
#       
      # name = "export_n_click_"+name_datetime.to_s
      # del_click_array = []
#       
#       
      # if total_clicks.count.to_i > 0
#           
          # click_array = []
          # all_click_hash = {}
#           
          # total_clicks.each do |total_clicks_d|
#             
              # del_click_array << total_clicks_d["_id"]
#                
              # array = []
              # array << total_clicks_d["user_id"]
              # array << total_clicks_d["cookie_id"]
              # array << total_clicks_d["company_id"]
              # array << total_clicks_d["network_id"]
              # array << total_clicks_d["network_type"]
              # array << total_clicks_d["campaign_id"]
              # array << total_clicks_d["adgroup_id"]
              # array << total_clicks_d["keyword_id"]
              # array << total_clicks_d["ad_id"]
              # array << total_clicks_d["search_q"]
              # array << total_clicks_d["ip"]
              # array << total_clicks_d["country"]
              # array << total_clicks_d["city"]
              # array << total_clicks_d["variant"]
              # array << total_clicks_d["user_agent"]
              # array << total_clicks_d["device"]
              # array << total_clicks_d["cookies"]
              # array << total_clicks_d["other_parameters"]
              # array << total_clicks_d["date"]
              # array << total_clicks_d["referer"]
              # array << total_clicks_d["destination_url"]
              # array << total_clicks_d["check_time_status"]
              # array << total_clicks_d["check_event_status"]
              # array << total_clicks_d["check_page_count_status"]
              # array << total_clicks_d["check_url_status"]
              # array << total_clicks_d["check_confirmation_status"]
#               
#               
#               
#               
              # click_array << array
#               
              # # this part is for different company
              # if all_click_hash[total_clicks_d["company_id"]].nil?
                # all_click_hash[total_clicks_d["company_id"]] = []
              # end
#               
              # all_click_hash[total_clicks_d["company_id"]] << array
#               
          # end
#         
          # p = Axlsx::Package.new
          # wb = p.workbook
#             
          # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
               # click_array.each_with_index do |csv, csv_index|
                  # begin
                  # sheet.add_row csv
                  # rescue Exception
                  # end
               # end
          # end
#           
          # create_excel_path = '/home/bmg/adeqo/public/export_click/'+name+'.xlsx'
          # p.serialize(create_excel_path)
#           
#           
          # if all_click_hash.count.to_i > 0
              # all_click_hash.each do |key, value|
#                 
                  # p = Axlsx::Package.new
                  # wb = p.workbook
#                     
                  # wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
                       # value.each_with_index do |csv, csv_index|
                          # begin
                          # sheet.add_row csv
                          # rescue Exception
                          # end
                       # end
                  # end
#                 
                  # create_excel_path = '/home/bmg/adeqo/public/export_click/n_company_id_'+key.to_s+'_'+name+'.xlsx'
                  # p.serialize(create_excel_path)
              # end
          # end
      # end
#       
#       
      # @db2["n_clicks"].find('_id' => { "$in" => del_click_array}).delete_many
      # @db2.close()
#       
#       
#       
      # # rescue Exception
      # # end
#       
      # @logger.info "export click file done"
      # data = {:export_click => total_clicks.count.to_i, :export_click_time => @one_hour_ago, :total_del_clicks => del_click_array.count.to_i, :status => "true"}
      # return render :json => data, :status => :ok
  # end
  
  
  def cleanclickfile
      begin
      @logger.info "clean click file"
      @all_click_files = Dir.glob('/home/bmg/adeqo/public/export_click/*')
      
      file_year = (Time.now - 1.day).to_date.strftime("%Y")
      file_month = (Time.now - 1.day).to_date.strftime("%m")
      file_day = (Time.now - 1.day).to_date.strftime("%d")
       
      file_date = file_year + "-" + file_month + "-" + file_day
      
      @all_click_files.each do |all_files_p|
          if all_files_p.to_s.include?(file_date) && !all_files_p.to_s.include?("company")
              File.delete(all_files_p) if File.exist?(all_files_p)
          end
      end
      rescue Exception
      end
      data = {:message => "clean click file", :clean_day => file_date, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  def getclickfile
      begin
      @one_hour_ago = Time.now - 1.hours
      name_datetime = @one_hour_ago.in_time_zone('Beijing').strftime("%Y-%m-%d-%H")
      
      domain_name = "http://china.adeqo.com:83/export_click/"      
      name = domain_name + "export_click_" + name_datetime + ".xlsx"
      
      download_name = "/home/bmg/adeqo/public/export_click/export_click_"+ name_datetime + ".xlsx"
      
      IO.copy_stream(open(name) , download_name)
      
      tmp_file_path = download_name
                    
      xlsx = Roo::Spreadsheet.open(tmp_file_path, extension: :xlsx)
      xlsx.each_with_index do |csv, csv_index|
         
          cookies_hash = {}
          csv_cookies_array = []
          
          if csv[18].to_s != "{}"
              csv_cookies_array = csv[18].to_s.gsub('{', '').gsub('}', '').split(",")
              
              
              csv_cookies_array.each do |csv_cookies_array_d|
                  temp_arr = csv_cookies_array_d.split("=>")
                  
                  if !temp_arr[0].nil?
                      name = temp_arr[0].gsub('"', '')
                  end
                  
                  if !temp_arr[1].nil?
                      value = temp_arr[1].gsub('"', '')
                  else
                      value = ""
                  end
                  
                  if !temp_arr[0].nil?
                      cookies_hash[name] = value
                  end
                  
                  cookies_hash[name] = value
              end
              
          end
          
          @db2[:clicks].insert_one({ 
                              id: csv[0].to_s, 
                              random_number: csv[1].to_i.to_s,
                              session_id: csv[2].to_s,
                              company_id: csv[3].to_i,
                              network_id: csv[4].to_i,
                              network_type: csv[5].to_s,
                              campaign_id: csv[6].to_i,
                              adgroup_id: csv[7].to_i,
                              keyword_id: csv[8].to_i,
                              ad_id: csv[9].to_i,
                              target_id: csv[10].to_s,
                              search_q: csv[11].to_s,
                              ip: csv[12],
                              country: csv[13].to_s,
                              city: csv[14].to_s,
                              variant: csv[15].to_s,
                              user_agent: csv[16].to_s,
                              device: csv[17].to_s,
                              cookies: cookies_hash,
                              other_parameters: csv[19].to_s,
                              date: csv[20].to_s,
                              referer: csv[21].to_s,
                              destination_url: csv[22].to_s
                            })
          @db2.close 
          
          
      end                    
      rescue Exception
      end     
      
      @all_click_files = Dir.glob('/home/bmg/adeqo/public/export_click/*')
          
      @all_click_files.each do |all_files_p|
          if all_files_p.to_s.include?(name_datetime)
              File.delete(all_files_p) if File.exist?(all_files_p)
          end
      end
                   
      data = {:message => "get and insert click", :clean_day => name_datetime, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  
  def cleanexportfile
    
      @all_export_files = Dir.glob('/home/bmg/adeqo/public/export_excel/*')
      
      # file_year = (Time.now - 1.day).to_date.strftime("%Y")
      # file_month = (Time.now - 1.day).to_date.strftime("%m")
      # file_day = (Time.now - 1.day).to_date.strftime("%d")
#       
      # file_date = file_year + "-" + file_month + "-" + file_day
      
      @all_export_files.each do |all_files_p|
          # if all_files_p.to_s.include?(file_date)
              File.delete(all_files_p) if File.exist?(all_files_p)
          # end
      end
      
      data = {:message => "clean export", :status => "true"}
      return render :json => data, :status => :ok
  end
    
  def cleanlogfile
      @all_log_files = Dir.glob('/home/bmg/adeqo/log/*')
      
      file_year = (Time.now - 1.month).to_date.strftime("%Y")
      file_month = (Time.now - 1.month).to_date.strftime("%m")
      
      file_date = file_year + "-" + file_month 
      
      @all_log_files.each do |all_files_p|
          if all_files_p.to_s.include?(file_date) && all_files_p.to_s.include?("logfile")
              File.delete(all_files_p) if File.exist?(all_files_p)
          end
      end
      
      data = {:message => "clean log", :status => "true", :file_date => file_date}
      return render :json => data, :status => :ok
  end  
    
  def defaultdayrange
      
      if session[:start_date].nil?
          session[:start_date] = @today - 1.days
      end
      
      if session[:end_date].nil?
          session[:end_date] = @today - 1.days
      end
        
  end
  
  
  def logger
    @day = Time.now.in_time_zone('Beijing').strftime("%Y-%m-%d")
    @logger = Logger.new('/home/bmg/adeqo/log/'+@day+'logfile.log')
  end
  
  
  def useragent
      @user_agent = request.user_agent
    
      case @user_agent
        when /iPad/i
          @variant = "tablet"
        when /iPhone/i
          @variant = "phone"
        when /Android/i && /mobile/i
          @variant = "phone"
        when /Android/i
          @variant = "tablet"
        when /Windows Phone/i
          @variant = "phone"
        else
          @variant = "desktop"
      end
  end
  
  def location
      @ip = request.remote_ip
      @geoip = GeoIP.new("#{Rails.root}/public/GeoLiteCity.dat")
      @location = @geoip.city(@ip)
      
      @country = @location[:country_name]
      @city = @location[:city_name]
  end
  
  
  
  
  def getconversion
      
      @all_company = @db[:company].find()
      @db.close
      conversion_array = []
      
      
      if @all_company.count.to_i > 0
          @all_company.each do |all_company_d|
            
                @events = @db[:events].find('company_id'=> all_company_d['id'].to_i, 'id' => { '$ne' => nil }, 'random_number' => { '$ne' => nil }, 'session_id' => { '$ne' => nil }).limit(100)
                @db.close
                
                if @events.count.to_i > 0
                 
                    @events.each do |events_d|
                        revenue = 0
                        
                        other_param_array = events_d['other_param'].split(",")
                        other_param_array.each do |other_param_array_d|
                          
                            # @logger.info other_param_array_d.to_s
                          
                            param_detail_array = other_param_array_d.split(":")
                            
                            if !param_detail_array[1].nil? && param_detail_array[1].include?("val")
                                revenue = param_detail_array[1].gsub('val=','').to_f  
                            end
                        end
                        
                        
                        @clicks = @db[:clicks].find(
                                                    'id' => events_d['id'],
                                                    'company_id' => events_d['company_id'].to_i,  
                                                    'network_id' => { '$ne' => 0}, 
                                                    'campaign_id' => { '$ne' => 0}, 
                                                    'adgroup_id' => { '$ne' => 0}, 
                                                    'ad_id' => { '$ne' => 0}
                    
                                                  )
                        @db.close                         
                                                  
                        if @clicks.count.to_i > 0
                              @clicks.each do |click_d|
                                    if click_d['keyword_id'].to_i == 0 then
                                      
                                        if click_d['target_id'].to_s != ""
                                            target_array = click_d['target_id'].to_s.split(":")
                                            
                                            target_array.each do |target_array_d|
                                                if target_array_d.to_s.include?("kwd-")
                                                    keyword_id = target_array_d.to_s.gsub('kwd-','').to_i
                                                end
                                            end
                                        end
                                          
                                    else
                                        keyword_id = click_d['keyword_id'].to_i
                                    end
                                    
                                    conversion = {}
                                    conversion[:id] = click_d['id']
                                    conversion[:random_number] = click_d['random_number']
                                    conversion[:session_id] = click_d['session_id']
                                    conversion[:tag_version] = click_d['tag_version'] 
                                    conversion[:company_id] = click_d['company_id']
                                    conversion[:network_id] = click_d['network_id']
                                    conversion[:campaign_id] = click_d['campaign_id']
                                    conversion[:adgroup_id] = click_d['adgroup_id']
                                    conversion[:ad_id] = click_d['ad_id']
                                    conversion[:keyword_id] = click_d['keyword_id']
                                    conversion[:revenue] = revenue
                                    conversion[:date] = click_d['date'] 
                                     
                                    conversion_array << conversion
                                    
                              end  
                        end    
                    end
                    
                end  
          end
      end
      
      
      
      
      data = {:conversion => conversion_array, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  
  def getevent
      @events = @db[:events].find("company_id" => nil)
      @db.close
      data = {:count => @events.count.to_i, :events => @events, :cookies => request.cookies, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  
  
  
  
  
  def event
    
        useragent()
        location()
        
        
        @tag_version = "3"
        @company_id = params[:companyid]
        @current_page = params[:current_page]
        @host = params[:host]
        @referrer = params[:referrer]
        
        # @host = request.host
        # @referrer = request.referer
        # @current_page = request.original_url
        
        
        
        
        
            
        @event_category = params[:event_category]
        @event_action = params[:event_action]
        @event_label = params[:event_label]
        @event_value = params[:event_value]

        
        
        @event_type = params[:event_type]
        @order_id = params[:order_id]
        @promotecode = params[:promotecode]
        @confirmation_category = params[:category]
        @price = params[:price]
        @revenue = params[:revenue]
        @confirmation_name = params[:name]
        @sku = params[:sku]
        @quantity = params[:quantity]
        
        @leave = params[:leave]
        
        
        @user_id = params[:user_id]
        @cookie_id = params[:cookie_id]
        
        
        logger.debug @cookie_id.to_s
        
        params_except_array = ["action","category","companyid","controller","event_type","name","order_id","price","promotecode","revenue","sku","quantity","current_page","host","referrer","leave"]
        params_array = []
        
        
        
        if params[:companyid].nil?
            @company_id = params[:cid]
        end
        
        
        
        if @user_id.nil? || @user_id.to_s == ""
            current_cookie = request.cookies
            
            if current_cookie["user_id"].nil? || current_cookie["user_id"].to_s == ""
          
                @user_id = SecureRandom.uuid + "_" + rand(1000000).to_s + "_" + @ip.to_s.gsub('.','_')
                
                cookies[:user_id] = {
                   :value => @user_id,
                   :domain => 'adeqo.com'
                }
                
            else
                @user_id = current_cookie["user_id"].to_s
            end
        end  
          
          
        if @cookie_id.nil? || @cookie_id.to_s == ""  
            @cookie_id = cookies[:cookie_id].to_s  
        end
        
        logger.debug @cookie_id.to_s
        
        
        # if @company_id.to_i == 1
            
            # begin
         
                # params.each do |key,value|
                    # if key.include?("param")
                        # params_array << key+":"+value
                    # end
                # end
#                 
                # if !cookies[:clicks_id].nil? && cookies[:clicks_id].to_s != ""
# #                   
                    # @db2[:test_events].insert_one({ 
                                            # id: cookies[:clicks_id], 
                                            # random_number: cookies[:clicks_random_id],
                                            # session_id: cookies[:clicks_session_id],
                                            # tag_version: @tag_version,
                                            # company_id: @company_id.to_i,
                                            # referer: request.referer,
                                            # ip: @ip,
                                            # country: @country,
                                            # city: @city,
                                            # variant: @variant,
                                            # user_agent: @user_agent,
                                            # cookies: request.cookies,
                                            # other_param: params_array,        
                                            # check_status: 0,                        
                                            # date: @now
                                          # })       
                    # @db2.close                      
                # end
            
            # rescue Exception
                # logger.debug "event: db is too busy"
            # end
#             
            # data = {:message => cookies, :status => "true"}
            # return render :json => data, :status => :ok
        # else
            
            
            params.each do |key,value|
                if !params_except_array.include?(key)
                    params_array << key+":"+value
                end
            end
        
            # @current_page = params[:current_page]
            # @host = params[:host]
            # @referrer = params[:referrer]
            
            begin
                # this part is for track goal:event
                if !params[:event_category].nil? && params[:event_category].to_s != "" && !params[:event_action].nil? && params[:event_action].to_s != ""
                  
                    @db2[:events].insert_one({ 
                                            
                                            type:"event_goal",
                                            user_id:@user_id.to_s,
                                            cookie_id: @cookie_id.to_s,
                                            
                                            tag_version: @tag_version,
                                            company_id: @company_id.to_i,
                                            host: @host.to_s,
                                            referer: @referrer.to_s,
                                            current_page: @current_page.to_s,
                                            ip: @ip,
                                            country: @country,
                                            city: @city,
                                            variant: @variant,
                                            user_agent: @user_agent,
                                            
                                            category: @event_category.to_s,
                                            action: @event_action.to_s,
                                            label: @event_label.to_s,
                                            value: @event_value.to_s,
                                            
                                            cookies: request.cookies,
                                            other_param: params_array,
                                            check_time_status: 1,
                                            check_event_status: 0,
                                            check_page_count_status: 1,
                                            check_url_status: 1,     
                                            check_confirmation_status: 1,      
                                            check_status: 1,                              
                                            date: @now
                                          })       
                    @db2.close
                
                elsif !params[:event_type].nil? && params[:event_type].to_s == "confirmation"
                  
        
                    @db2[:events].insert_one({ 
                                            
                                            type:"confirmation",
                                            user_id:@user_id.to_s,
                                            cookie_id: @cookie_id.to_s,
                                            
                                            tag_version: @tag_version,
                                            company_id: @company_id.to_i,
                                            host: @host.to_s,
                                            referer: @referrer.to_s,
                                            current_page: @current_page.to_s,
                                            ip: @ip,
                                            country: @country,
                                            city: @city,
                                            variant: @variant,
                                            user_agent: @user_agent,
                                            
                                            order_id: @order_id.to_s,
                                            promotecode: @promotecode.to_s,
                                            confirmation_category: @confirmation_category.to_s,
                                            price: @price.to_f,
                                            revenue: @revenue.to_f,
                                            confirmation_name: @confirmation_name.to_s,
                                            sku: @sku.to_s,
                                            quantity: @quantity.to_s,
                                            
                                            
                                            cookies: request.cookies,
                                            other_param: params_array,
                                            check_time_status: 1,
                                            check_event_status: 1,
                                            check_page_count_status: 1,
                                            check_url_status: 1,
                                            check_confirmation_status: 0,  
                                            check_status: 1,                              
                                            date: @now
                                          })       
                    @db2.close
                    # data = {:order_id => @order_id, :price => @price, :revenue => @revenue, :name => @name, :sku => @sku, :category => @category, :status => "true"}
                    # return render :json => data, :status => :ok
                    
                elsif @company_id.to_i > 0
                    
                    if @leave.nil?
                      
                        @db2[:events].insert_one({ 
                                                
                                                type:"other_goal",
                                                user_id:@user_id.to_s,
                                                cookie_id: @cookie_id.to_s,
                                                
                                                tag_version: @tag_version,
                                                company_id: @company_id.to_i,
                                                host: @host.to_s,
                                                referer: @referrer.to_s,
                                                current_page: @current_page.to_s,
                                                ip: @ip,
                                                country: @country,
                                                city: @city,
                                                variant: @variant,
                                                user_agent: @user_agent,
                                                cookies: request.cookies,
                                                other_param: params_array,
                                                check_time_status: 0,
                                                check_event_status: 1,
                                                check_page_count_status: 0,
                                                check_url_status: 0,
                                                check_confirmation_status: 1,   
                                                check_status: 1,                     
                                                leave: "",        
                                                date: @now
                                              })       
                        @db2.close
                        
                    else
                        
                        @db2[:events].insert_one({ 
                                                
                                                type:"other_goal",
                                                user_id:@user_id.to_s,
                                                cookie_id:@cookie_id.to_s,
                                                
                                                tag_version: @tag_version,
                                                company_id: @company_id.to_i,
                                                host: @host.to_s,
                                                referer: @referrer.to_s,
                                                current_page: @current_page.to_s,
                                                ip: @ip,
                                                country: @country,
                                                city: @city,
                                                variant: @variant,
                                                user_agent: @user_agent,
                                                cookies: request.cookies,
                                                other_param: params_array,
                                                check_time_status: 0,
                                                check_event_status: 1,
                                                check_page_count_status: 1,
                                                check_url_status: 1,
                                                check_confirmation_status: 1,   
                                                check_status: 1,                     
                                                leave: @leave.to_s,        
                                                date: @now
                                              })       
                        @db2.close
                        
                    end
                end     
                                     
            rescue Exception
                logger.debug "event: db is too busy"
            end
            
            
        # end
        
         
        
         
        
        # data = {:click_id => cookies[:clicks_id], :cookies => request.cookies, :status => "true"}
        # return render :json => data, :status => :ok
        
        
        return render :nothing => true, :status => 200, :content_type => 'text/javascript'
  end
  
  
  
  # def event
#     
        # useragent()
        # location()
#         
#         
        # @tag_version = "2"
        # @company_id = params[:companyid]
        # @current_page = params[:current_page]
        # @host = params[:host]
        # @referrer = params[:referrer]
#         
#         
#             
        # @event_category = params[:event_category]
        # @event_action = params[:event_action]
        # @event_label = params[:event_label]
        # @event_value = params[:event_value]
# 
#         
#         
        # @event_type = params[:event_type]
        # @order_id = params[:order_id]
        # @promotecode = params[:promotecode]
        # @confirmation_category = params[:category]
        # @price = params[:price]
        # @revenue = params[:revenue]
        # @confirmation_name = params[:name]
        # @sku = params[:sku]
        # @quantity = params[:quantity]
#         
        # params_array = []
#         
#         
        # if params[:companyid].nil?
            # @company_id = params[:cid]
        # end
#         
#         
        # current_cookie = request.cookies
#         
        # if current_cookie["user_id"].nil? || current_cookie["user_id"].to_s == ""
#       
            # @user_id = SecureRandom.uuid + "_" + rand(1000000).to_s + "_" + @ip.to_s.gsub('.','_')
#             
            # cookies[:user_id] = {
               # :value => @user_id,
               # :domain => 'adeqo.com'
            # }
#             
        # else
            # @user_id = current_cookie["user_id"].to_s
        # end
#           
        # if @company_id.to_i == 1
#             
            # begin
#                 
#          
                # params.each do |key,value|
                    # if key.include?("param")
                        # params_array << key+":"+value
                    # end
                # end
#                 
                # if !cookies[:clicks_id].nil? && cookies[:clicks_id].to_s != ""
#                   
                    # @db2[:events].insert_one({ 
                                            # id: cookies[:clicks_id], 
                                            # random_number: cookies[:clicks_random_id],
                                            # session_id: cookies[:clicks_session_id],
                                            # tag_version: @tag_version,
                                            # company_id: @company_id.to_i,
                                            # referer: request.referer,
                                            # ip: @ip,
                                            # country: @country,
                                            # city: @city,
                                            # variant: @variant,
                                            # user_agent: @user_agent,
                                            # cookies: request.cookies,
                                            # other_param: params_array,        
                                            # check_status: 0,                        
                                            # date: @now
                                          # })       
                    # @db2.close                      
                # end
#             
            # rescue Exception
                # logger.debug "event: db is too busy"
            # end
#             
        # else
#             
            # @current_page = params[:current_page]
            # @host = params[:host]
            # @referrer = params[:referrer]
#             
            # begin
                # # this part is for track goal:event
                # if !params[:event_category].nil? && params[:event_category].to_s != "" && !params[:event_action].nil? && params[:event_action].to_s != ""
#                   
                    # @db2[:n_events].insert_one({ 
#                                             
                                            # type:"event_goal",
                                            # user_id:@user_id.to_s,
                                            # cookie_id:cookies[:cookie_id].to_s,
#                                             
                                            # tag_version: @tag_version,
                                            # company_id: @company_id.to_i,
                                            # host: @host.to_s,
                                            # referer: @referrer.to_s,
                                            # current_page: @current_page.to_s,
                                            # ip: @ip,
                                            # country: @country,
                                            # city: @city,
                                            # variant: @variant,
                                            # user_agent: @user_agent,
#                                             
                                            # category: @event_category.to_s,
                                            # action: @event_action.to_s,
                                            # label: @event_label.to_s,
                                            # value: @event_value.to_s,
#                                             
                                            # cookies: request.cookies,
                                            # other_param: params_array,
                                            # check_time_status: 1,
                                            # check_event_status: 0,
                                            # check_page_count_status: 1,
                                            # check_url_status: 1,     
                                            # check_confirmation_status: 1,      
                                            # check_status: 1,                              
                                            # date: @now
                                          # })       
                    # @db2.close
#                 
                # elsif !params[:event_type].nil? && params[:event_type].to_s == "confirmation"
#                   
#         
                    # @db2[:n_events].insert_one({ 
#                                             
                                            # type:"confirmation",
                                            # user_id:@user_id.to_s,
                                            # cookie_id:cookies[:cookie_id].to_s,
#                                             
                                            # tag_version: @tag_version,
                                            # company_id: @company_id.to_i,
                                            # host: @host.to_s,
                                            # referer: @referrer.to_s,
                                            # current_page: @current_page.to_s,
                                            # ip: @ip,
                                            # country: @country,
                                            # city: @city,
                                            # variant: @variant,
                                            # user_agent: @user_agent,
#                                             
                                            # order_id: @order_id.to_s,
                                            # promotecode: @promotecode.to_s,
                                            # confirmation_category: @confirmation_category.to_s,
                                            # price: @price.to_f,
                                            # revenue: @revenue.to_f,
                                            # confirmation_name: @confirmation_name.to_s,
                                            # sku: @sku.to_s,
                                            # quantity: @quantity.to_s,
#                                             
                                            # cookies: request.cookies,
                                            # other_param: params_array,
                                            # check_time_status: 1,
                                            # check_event_status: 1,
                                            # check_page_count_status: 1,
                                            # check_url_status: 1,
                                            # check_confirmation_status: 0,  
                                            # check_status: 1,                              
                                            # date: @now
                                          # })       
                    # @db2.close
                    # # data = {:order_id => @order_id, :price => @price, :revenue => @revenue, :name => @name, :sku => @sku, :category => @category, :status => "true"}
                    # # return render :json => data, :status => :ok
#                     
                # else
#                 
                    # @db2[:n_events].insert_one({ 
#                                             
                                            # type:"other_goal",
                                            # user_id:@user_id.to_s,
                                            # cookie_id:cookies[:cookie_id].to_s,
#                                             
                                            # tag_version: @tag_version,
                                            # company_id: @company_id.to_i,
                                            # host: @host.to_s,
                                            # referer: @referrer.to_s,
                                            # current_page: @current_page.to_s,
                                            # ip: @ip,
                                            # country: @country,
                                            # city: @city,
                                            # variant: @variant,
                                            # user_agent: @user_agent,
                                            # cookies: request.cookies,
                                            # other_param: params_array,
                                            # check_time_status: 0,
                                            # check_event_status: 1,
                                            # check_page_count_status: 0,
                                            # check_url_status: 0,
                                            # check_confirmation_status: 1,   
                                            # check_status: 1,                             
                                            # date: @now
                                          # })       
                    # @db2.close
                # end     
#                                      
            # rescue Exception
                # logger.debug "event: db is too busy"
            # end
#             
#             
        # end
#         
#          
#         
#          
#         
        # # data = {:click_id => cookies[:clicks_id], :cookies => request.cookies, :status => "true"}
        # # return render :json => data, :status => :ok
#         
#         
        # return render :nothing => true, :status => 200, :content_type => 'text/javascript'
  # end 
  
  
  
  
  
  
  
  
  
  
  
  
  
  def getclick
      @clicks = @db[:clicks].find('referer' => { '$ne' => nil }).limit(100)
      
      @db.close
      data = {:count => @db[:clicks].find().count.to_i, :clicks => @clicks, :cookies => request.cookies, :status => "true"}
      return render :json => data, :status => :ok
  end
  
  
  
  
  
  
  
  
  def click
     
    useragent()
    location()
    
    
    @cookie_id = SecureRandom.uuid + "-" + rand(1000000).to_s + "-" + SecureRandom.uuid
    
    current_cookie = request.cookies
    
    total_minutes = 1
    
    @company_id = params[:company_id]
    @network_id = params[:network_id]
    @campaign_id = params[:campaign_id]
    @adgroup_id = params[:adgroup_id]
    @ad_id = params[:ad_id]
    @keyword_id = params[:keyword_id]
    @durl = params[:durl]
    @search_q = ""
    
    # @target_id = params[:target_id]
    
    @cookie = params[:cookie]
    @device = params[:device]
    
    if @device.to_s == ""
        @device = "pc"
    end
    
    @test = params[:test]
    
    if !@test.nil? || @network_id.to_i == 0
      data = {:@durl => @durl}
      return render :json => data, :status => :ok
    end
    
    if current_cookie["user_id"].nil? || current_cookie["user_id"].to_s == ""
      
        @user_id = SecureRandom.uuid + "_" + rand(1000000).to_s + "_" + @ip.to_s.gsub('.','_')
        
        cookies[:user_id] = {
           :value => @user_id,
           :domain => 'adeqo.com'
        }
        
    else
        @user_id = current_cookie["user_id"].to_s
    end
    
    
    if @cookie.nil? || @cookie.to_i == 0 
        expire_day = 30
    else
        expire_day = @cookie.to_i
    end
    
    cookies[:cookie_id] = {
                             :value => @cookie_id,
                             :expires => expire_day.days.from_now,
                             :domain => 'adeqo.com'
                          }
    
    
    
    # |||||||||||||||||||||||||||||||||||||||||||||||||||||||| old one
    # if @company_id.to_i == 1
        # @id = SecureRandom.uuid
        # @random_number = rand(1000000)
        # @session_id = SecureRandom.uuid
#         
#         
        # cookies[:clicks_id] = {
           # :value => @id,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
        # cookies[:clicks_random_id] = {
           # :value => @random_number,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
        # cookies[:clicks_session_id] = {
           # :value => @session_id,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
    # end
    # |||||||||||||||||||||||||||||||||||||||||||||||||||||||| old one 
    
    
    
    # cookies.delete :clicks_id, :domain => 'adeqo.com'
    # cookies.delete :clicks_random_id, :domain => 'adeqo.com'
    # cookies.delete :clicks_session_id, :domain => 'adeqo.com'
    
    
    @network_type = ""
    
    if request.referer.to_s.include?("bing")
        @search_q = params[:q].to_s + "," + params[:pq].to_s
        
        @network_type = "bing"
    end
    
    
    if request.referer.to_s.include?("google")
        @search_q = params[:q].to_s + "," + params[:as_q].to_s + "," + params[:oq].to_s
        
        @network_type = "google"
    end
    
    if request.referer.to_s.include?("360") || request.referer.to_s.include?("haosou.com") || request.referer.to_s.include?("so.com")
         
        @referr_array = request.referer.split("?")
        @referr_param_array = @referr_array[1]
        
        if !@referr_param_array.nil?
            @referr_param_array = @referr_param_array.split("&")
            @search_q_array = []
            
            # @search_q_array << params[:q].to_s
            # @search_q_array << params[:pq].to_s
            
            @referr_param_array.each do |ref|
                @referr_keyword_array = ref.split("=")
                if ref.to_s.include?("keyword") || @referr_keyword_array[0].to_s == "p" || ref.to_s.include?("query") || @referr_keyword_array[0].to_s == "q"  
                    
                    @search_q_array << URI.unescape(@referr_keyword_array[1].to_s)
                    # @search_q = @search_q.to_s + "," + URI.unescape(@referr_keyword_array[1].to_s)
                end          
            end
            
            @search_q = @search_q_array.join(",") 
        else
            @search_q = ""
        end 
        @network_type = "360"
    end
    
    if request.referer.to_s.include?("baidu")
        @network_type = "baidu"
    end
    
    if request.referer.to_s.include?("shenma")
        @network_type = "shenma"
    end
    
    
    if request.referer.to_s.include?("sogou")
        
        @referr_array = request.referer.split("?")
        @referr_param_array = @referr_array[1]
        
        if !@referr_param_array.nil?
          @referr_param_array = @referr_param_array.split("&") 
          @search_q_array = []
          
          @referr_param_array.each do |ref|
              @referr_keyword_array = ref.split("=")
              if ref.to_s.include?("keyword") || @referr_keyword_array[0].to_s == "p" || ref.to_s.include?("query")
                  @search_q_array << URI.unescape(@referr_keyword_array[1].to_s)
                  # @search_q = @search_q.to_s + "," + URI.unescape(@referr_keyword_array[1].to_s)
              end          
          end
          
          @search_q = @search_q_array.join(",")
        else
          @search_q = ""
        end
                
        @network_type = "sogou"
    end
    
    
    begin
      
       # if @company_id.to_i == 1
#           
          # @db2[:test_clicks].insert_one({ 
                              # id: @id.to_s, 
                              # random_number: @random_number.to_s,
                              # session_id: @session_id.to_s,
                              # company_id: @company_id.to_i,
                              # network_id: @network_id.to_i,
                              # network_type: @network_type.to_s,
                              # campaign_id: @campaign_id.to_i,
                              # adgroup_id: @adgroup_id.to_i,
                              # keyword_id: @keyword_id.to_i,
                              # ad_id: @ad_id.to_i,
                              # target_id: @target_id.to_s,
                              # search_q: @search_q.to_s,
                              # ip: @ip,
                              # country: @country,
                              # city: @city,
                              # variant: @variant,
                              # user_agent: @user_agent,
                              # device: @device,
                              # cookies: request.cookies,
                              # date: @now,
                              # referer: request.referer,
                              # destination_url: @durl
                            # })
          # @db2.close
#         
       # else
       
           @db2[:clicks].insert_one({ 
             
                                  user_id: @user_id.to_s,
                                  cookie_id: @cookie_id.to_s,
                                  company_id: @company_id.to_i,
                                  network_id: @network_id.to_i,
                                  network_type: @network_type.to_s,
                                  campaign_id: @campaign_id.to_i,
                                  adgroup_id: @adgroup_id.to_i,
                                  keyword_id: @keyword_id.to_i,
                                  ad_id: @ad_id.to_i,
                                  search_q: @search_q.to_s,
                                  ip: @ip,
                                  country: @country,
                                  city: @city,
                                  variant: @variant,
                                  user_agent: @user_agent,
                                  device: @device,
                                  cookies: request.cookies,
                                  date: @now,
                                  referer: request.referer,
                                  destination_url: @durl,
                                  check_time_status: 0,
                                  check_event_status: 0,
                                  check_page_count_status: 0,
                                  check_url_status: 0,
                                  check_confirmation_status: 0
                                })
            @db2.close 
        # end
        
    rescue Exception
        logger.debug "DB is somehow not working, can't insert clicks, add email function in application controller later."
    end
    
    
    
    
    
    
    begin
        return redirect_to @durl
    rescue Exception
        return redirect_to "http://china.adeqo.com"
    end
    # data = {:uid => @id,:random_number => @random_number,:session_id => @session_id, :company_id => @company_id,:network_id => @network_id,:campaign_id => @campaign_id,:adgroup_id => @adgroup_id, :ad_id => @ad_id, :keyword_id => @keyword_id, :durl => @durl, :status => "true"}
    # return render :json => data, :status => :ok

  end
  
  
  
  # def click
#      
    # useragent()
    # location()
#     
#     
    # @cookie_id = SecureRandom.uuid + "-" + rand(1000000).to_s + "-" + SecureRandom.uuid
#     
    # current_cookie = request.cookies
#     
    # total_minutes = 1
#     
    # @company_id = params[:company_id]
    # @network_id = params[:network_id]
    # @campaign_id = params[:campaign_id]
    # @adgroup_id = params[:adgroup_id]
    # @ad_id = params[:ad_id]
    # @keyword_id = params[:keyword_id]
    # @durl = params[:durl]
    # @search_q = ""
#     
    # # @target_id = params[:target_id]
#     
    # @cookie = params[:cookie]
    # @device = params[:device]
#     
    # if @device.to_s == ""
        # @device = "pc"
    # end
#     
    # @test = params[:test]
#     
    # if !@test.nil? || @network_id.to_i == 0
      # data = {:@durl => @durl}
      # return render :json => data, :status => :ok
    # end
#     
    # if current_cookie["user_id"].nil? || current_cookie["user_id"].to_s == ""
#       
        # @user_id = SecureRandom.uuid + "_" + rand(1000000).to_s + "_" + @ip.to_s.gsub('.','_')
#         
        # cookies[:user_id] = {
           # :value => @user_id,
           # :domain => 'adeqo.com'
        # }
#         
    # else
        # @user_id = current_cookie["user_id"].to_s
    # end
#     
#     
    # if @cookie.nil? || @cookie.to_i == 0 
        # expire_day = 30
    # else
        # expire_day = @cookie.to_i
    # end
#     
    # cookies[:cookie_id] = {
                             # :value => @cookie_id,
                             # :expires => expire_day.days.from_now,
                             # :domain => 'adeqo.com'
                          # }
#     
#     
#     
    # # |||||||||||||||||||||||||||||||||||||||||||||||||||||||| old one
    # if @company_id.to_i == 1
        # @id = SecureRandom.uuid
        # @random_number = rand(1000000)
        # @session_id = SecureRandom.uuid
#         
#         
        # cookies[:clicks_id] = {
           # :value => @id,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
        # cookies[:clicks_random_id] = {
           # :value => @random_number,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
        # cookies[:clicks_session_id] = {
           # :value => @session_id,
           # :expires => expire_day.days.from_now,
           # :domain => 'adeqo.com'
        # }
    # end
    # # |||||||||||||||||||||||||||||||||||||||||||||||||||||||| old one 
#     
    # @network_type = ""
#     
    # if request.referer.to_s.include?("bing")
        # @search_q = params[:q].to_s + "," + params[:pq].to_s
#         
        # @network_type = "bing"
    # end
#     
#     
    # if request.referer.to_s.include?("google")
        # @search_q = params[:q].to_s + "," + params[:as_q].to_s + "," + params[:oq].to_s
#         
        # @network_type = "google"
    # end
#     
    # if request.referer.to_s.include?("360") || request.referer.to_s.include?("haosou.com") || request.referer.to_s.include?("so.com")
#          
        # @referr_array = request.referer.split("?")
        # @referr_param_array = @referr_array[1]
#         
        # if !@referr_param_array.nil?
            # @referr_param_array = @referr_param_array.split("&")
            # @search_q_array = []
#             
            # # @search_q_array << params[:q].to_s
            # # @search_q_array << params[:pq].to_s
#             
            # @referr_param_array.each do |ref|
                # @referr_keyword_array = ref.split("=")
                # if ref.to_s.include?("keyword") || @referr_keyword_array[0].to_s == "p" || ref.to_s.include?("query") || @referr_keyword_array[0].to_s == "q"  
#                     
                    # @search_q_array << URI.unescape(@referr_keyword_array[1].to_s)
                    # # @search_q = @search_q.to_s + "," + URI.unescape(@referr_keyword_array[1].to_s)
                # end          
            # end
#             
            # @search_q = @search_q_array.join(",") 
        # else
            # @search_q = ""
        # end 
        # @network_type = "360"
    # end
#     
    # if request.referer.to_s.include?("baidu")
        # @network_type = "baidu"
    # end
#     
    # if request.referer.to_s.include?("shenma")
        # @network_type = "shenma"
    # end
#     
#     
    # if request.referer.to_s.include?("sogou")
#         
        # @referr_array = request.referer.split("?")
        # @referr_param_array = @referr_array[1]
#         
        # if !@referr_param_array.nil?
          # @referr_param_array = @referr_param_array.split("&") 
          # @search_q_array = []
#           
          # @referr_param_array.each do |ref|
              # @referr_keyword_array = ref.split("=")
              # if ref.to_s.include?("keyword") || @referr_keyword_array[0].to_s == "p" || ref.to_s.include?("query")
                  # @search_q_array << URI.unescape(@referr_keyword_array[1].to_s)
                  # # @search_q = @search_q.to_s + "," + URI.unescape(@referr_keyword_array[1].to_s)
              # end          
          # end
#           
          # @search_q = @search_q_array.join(",")
        # else
          # @search_q = ""
        # end
#                 
        # @network_type = "sogou"
    # end
#     
#     
    # params_array = []
#     
    # params.each do |key,value|
        # if key.include?("params")
            # params_array << key+":"+value
        # end
    # end
#     
    # begin
#       
       # if @company_id.to_i == 1
#           
          # @db2[:test_clicks].insert_one({ 
                              # id: @id.to_s, 
                              # random_number: @random_number.to_s,
                              # session_id: @session_id.to_s,
                              # company_id: @company_id.to_i,
                              # network_id: @network_id.to_i,
                              # network_type: @network_type.to_s,
                              # campaign_id: @campaign_id.to_i,
                              # adgroup_id: @adgroup_id.to_i,
                              # keyword_id: @keyword_id.to_i,
                              # ad_id: @ad_id.to_i,
                              # target_id: @target_id.to_s,
                              # search_q: @search_q.to_s,
                              # ip: @ip,
                              # country: @country,
                              # city: @city,
                              # variant: @variant,
                              # user_agent: @user_agent,
                              # device: @device,
                              # cookies: request.cookies,
                              # other_parameters: params_array.join(","),
                              # date: @now,
                              # referer: request.referer,
                              # destination_url: @durl
                            # })
          # @db.close
#         
       # else
#        
           # @db2[:test_clicks].insert_one({ 
#              
                                  # user_id: @user_id.to_s,
                                  # cookie_id: @cookie_id.to_s,
                                  # company_id: @company_id.to_i,
                                  # network_id: @network_id.to_i,
                                  # network_type: @network_type.to_s,
                                  # campaign_id: @campaign_id.to_i,
                                  # adgroup_id: @adgroup_id.to_i,
                                  # keyword_id: @keyword_id.to_i,
                                  # ad_id: @ad_id.to_i,
                                  # search_q: @search_q.to_s,
                                  # ip: @ip,
                                  # country: @country,
                                  # city: @city,
                                  # variant: @variant,
                                  # user_agent: @user_agent,
                                  # device: @device,
                                  # cookies: request.cookies,
                                  # other_parameters: params_array.join(","),
                                  # date: @now,
                                  # referer: request.referer,
                                  # destination_url: @durl,
                                  # check_time_status: 0,
                                  # check_event_status: 0,
                                  # check_page_count_status: 0,
                                  # check_url_status: 0,
                                  # check_confirmation_status: 0
                                # })
            # @db2.close 
        # end
#         
    # rescue Exception
        # logger.debug "DB is somehow not working, can't insert clicks, add email function in application controller later."
    # end
#     
#     
#     
#     
#     
#     
    # begin
        # return redirect_to @durl
    # rescue Exception
        # return redirect_to "http://china.adeqo.com"
    # end
    # # data = {:uid => @id,:random_number => @random_number,:session_id => @session_id, :company_id => @company_id,:network_id => @network_id,:campaign_id => @campaign_id,:adgroup_id => @adgroup_id, :ad_id => @ad_id, :keyword_id => @keyword_id, :durl => @durl, :status => "true"}
    # # return render :json => data, :status => :ok
# 
  # end
  
  
  
    
  
   
  
  
  
  
  def drop
    
    # @db[:test].drop()
#     
    # @db[:last_user_id].drop()
    # @db[:last_company_id].drop()
    # @db[:last_network_id].drop()
#     
    # @db[:user].drop()
    # @db[:company].drop()
    # @db[:network].drop()
    # @db[:clicks].drop()
    # @db[:events].drop()
#     
    # @db[:network_user].drop()
    # @db[:campaign_sogou].drop()
    # @db[:adgroup_sogou].drop()
    # @db[:ad_sogou].drop()
    # @db[:keyword_sogou].drop()
#     
    # @db[:sogou_report_account].drop()
    # @db[:sogou_report_campaign].drop()
    # @db[:sogou_report_adgroup].drop()
    # @db[:sogou_report_ad].drop()
    # @db[:sogou_report_keyword].drop()
# 
#     
#     
#     
    # session[:user_id] = nil
    # return redirect_to "/"
  end
  
  def get_last_id(table)
    id = 0
    
    if table == "user"
        @db[:last_user_id].find.each do |last|
           id = last["id"]
        end
        @db.close
    end
    
    if table == "company"
        @db[:last_company_id].find.each do |last|
           id = last["id"]
        end
        @db.close
    end
    
    if table == "network"
        @db[:last_network_id].find.each do |last|
           id = last["id"]
        end
        @db.close
    end
    
    return id    
  end
  
  def update_last_id(table,update_id)
    
    if table == "user"
        @db[:last_user_id].drop()
        @db.close
        @db[:last_user_id].insert_one({
          id: update_id
        })
        @db.close
    end
    
    if table == "company"
        @db[:last_company_id].drop()
        @db.close
        @db[:last_company_id].insert_one({
          id: update_id
        })
        @db.close
    end
    
    if table == "network"
        @db[:last_network_id].drop()
        @db.close
        @db[:last_network_id].insert_one({
          id: update_id
        })
        @db.close
    end
    
    
    
    
  end
  
 
  
  
  def now
    @now = Time.now.in_time_zone('Beijing').strftime("%Y-%m-%d %H:%M:%S %Z")
    @today = Date.today.in_time_zone('Beijing')
  end
  
  
  def loginuser
    # @logger.info "Load Application Login user "+ @now.to_s
    if !session[:user_id].nil?
      # @logger.info "user "+ session[:user_id].to_s
      return redirect_to "/dashboard"
    end
  end
  
  
  def authuser    
    
    if session[:user_id].nil?
      return redirect_to "/"
    end
      
    @current_user = @db[:user].find('id' => session[:user_id])
    @db.close
    @user_count = @current_user.count.to_i
    
    if @user_count != 1
      session[:user_id] = nil
      return redirect_to "/"
    end
    
    @current_user.each do |doc|
      @user_company_id = doc["company_id"]
      @user_role = doc["role"]
      @user_name = doc["username"]
      @currency = doc["currency"]
      @current_user_status = doc["status"]
      @current_user_email = doc["email"]
    end
    
    if @current_user_status.to_s != "start"
      session[:user_id] = nil
      return redirect_to "/"
    end
    
    @user_company = @db[:company].find('id' => @user_company_id)
    @db.close
    @all_user_in_company = @db[:user].find('company_id' => @user_company_id)
    @db.close
  end
   
  
  def db
     
    # @db = Mongo::Client.new([ '10.204.176.17:27017' ], :database => 'adeqo', :connect => :direct , :timeout => 2, :max_pool_size => 30, :pool_timeout => 2, :socket_timeout => 2, :connect_timeout => 2)
    
    if @db2.nil?
    @db2 = Mongo::Client.new([ '10.215.106.65:27017' ], :database => 'adeqo', :connect => :direct , :timeout => 1, :max_pool_size => 1, :pool_timeout => 1, :socket_timeout => 1, :connect_timeout => 1)
    @db2.close()
    end
    # @db3 = Mongo::Client.new([ '10.204.210.32:27017' ], :database => 'adeqo', :connect => :direct , :timeout => 2, :max_pool_size => 30, :pool_timeout => 2, :socket_timeout => 2, :connect_timeout => 2)
    
    # @db.close
    
    # @db3.close
  end
  
  
  
end
