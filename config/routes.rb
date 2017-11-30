Rails.application.routes.draw do
  
  resources :networks

  resources :users
  resources :homes
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  
  
  # You can have the root of your site routed with "root"
  root 'application#not_found'
  
  # get '/demo' => 'homes#demo'
  # get '/contact_us' => 'homes#contact_us'
  
  # post '/send_demo_email' => 'homes#send_demo_email'
  # post '/send_contact_us_email' => 'homes#send_contact_us_email'
  
  
  get '/test' => 'homes#index'
  
  get '/cleaneventfile' => 'application#cleaneventfile'
  get '/exporteventfile' => 'application#exporteventfile'
  get '/geteventfile' => 'application#geteventfile'
  
  get '/cleanclickfile' => 'application#cleanclickfile'
  get '/exportclickfile' => 'application#exportclickfile'
  get '/getclickfile' => 'application#getclickfile'
  
  get '/cleanexportfile' => 'application#cleanexportfile'
  get '/cleanlogfile' => 'application#cleanlogfile'
  
  # post '/getuser' => 'users#getuser'
  # post '/edituser' => 'users#edituser'
  # post '/switchuserstatus' => 'users#switchuserstatus'
  # post '/createnewuser' => 'users#createnewuser'
  # post '/removeuser' => 'users#removeuser'
#   
  # post '/createnetwork' => 'networks#createnetwork'
  # post '/removenetwork' => 'networks#removenetwork'
  # post '/getnetwork' => 'networks#getnetwork'
  # post '/editnetwork' => 'networks#editnetwork'
  
  # post '/csv' => 'networks#csv'
  # get '/csv' => 'networks#csv'
  
  # post '/login' => 'users#login'
  # get '/login' => 'users#login'
  # post '/logout' => 'users#logout'
  # get '/logout' => 'users#logout'
#   
  # post '/updatepw' => 'users#updatepw'
  # post '/updatemail' => 'users#updatemail'
#   
  # post '/addnetworkuser' => 'networks#addnetworkuser'
  # post '/removenetworkuser' => 'networks#removenetworkuser'
#   
  # get '/dashboard' => 'homes#dashboard'
  # get '/dashboard/detail' => 'homes#dashboarddetail'
  
  # get '/getdashboard' => 'homes#getdashboard'
  # post '/getdashboard' => 'homes#getdashboard'
  
  # get '/getdashboarddetail' => 'homes#getdashboarddetail'
  # post '/getdashboarddetail' => 'homes#getdashboarddetail'
  
  
  # get '/account/' => 'users#account'  
  # get '/account/password' => 'users#editpassword'  
  # get '/account/user' => 'users#user'
  # get '/account/tracking' => 'users#tracking'
  # get '/account/portfolio' => 'users#portfolio'
  
  
  # get '/channel/accounts' => 'networks#channelaccounts'
  # post '/getnetworkaccounts' => 'networks#getnetworkaccounts'
  # post '/channel/sync' => 'networks#sync'
  
  # get '/channel/:id/campaigns' => 'networks#campaigns'
  # get '/campaigns' => 'networks#campaigns'
  # get '/campaigns/:campaign_type' => 'networks#campaigns'
  # get '/campaigns/:id/:type/:networkid/overview' => 'networks#campaignoverview'
  # get '/campaigns/:id/:type/:networkid/setting' => 'networks#campaignsetting'
  # get '/campaigns/:id/:type/:networkid/adgroup' => 'networks#campaignadgroup'
#   
  # get '/campaigns/:id/:type/:networkid/ads' => 'networks#campaignads'
  # get '/campaigns/:id/:type/:networkid/adgroup/:adgroupid/ads' => 'networks#campaignads'
#   
  # get '/campaigns/:id/:type/:networkid/keyword' => 'networks#campaignkeyword'
  # get '/campaigns/:id/:type/:networkid/adgroup/:adgroupid/keyword' => 'networks#campaignkeyword'
#   
  # get '/clickactivity/:type/:id' => 'networks#clickactivity'
#   
  # post '/getclickactivity' => 'networks#getclickactivity'
  
  # get '/getcampaigns' => 'networks#getcampaigns'
  # post '/getcampaigns' => 'networks#getcampaigns'
#   
  # # get '/getcampaignoverview' => 'networks#getcampaignoverview'
  # post '/getcampaignoverview' => 'networks#getcampaignoverview'
#   
  # # get '/getcampaignadgroup' => 'networks#getcampaignadgroup'
  # post '/getcampaignadgroup' => 'networks#getcampaignadgroup'
#   
  # # get '/getcampaignads' => 'networks#getcampaignads'
  # post '/getcampaignads' => 'networks#getcampaignads'
#   
  # # get '/getcampaignkeyword' => 'networks#getcampaignkeyword'
  # post '/getcampaignkeyword' => 'networks#getcampaignkeyword'
  
  #this one is for testing
  get '/getevent' => 'application#getevent'
  
  #this two is for inserting
  get '/get_event' => 'application#event'
  get '/event' => 'application#event'
  #this two is for inserting
  
  get '/getclick' => 'application#getclick'
  get '/click' => 'application#click'
  
  # post '/sogous/updatead' => 'networks#sogouupdatead'
  # post '/threesixties/updatead' => 'networks#threesixtyupdatead'
  
  
  # post '/sogous/updatekeyword' => 'networks#sogouupdatekeyword'
  # post '/threesixties/updatekeyword' => 'networks#threesixtyupdatekeyword'
  
  
  # post '/sogous/updateadgroup' => 'networks#sogouupdateadgroup'
  # post '/threesixties/updateadgroup' => 'networks#threesixtyupdateadgroup'
    
  # post '/updatecampaign' => 'networks#allupdatecampaign'
#     
  # get '/advancedsearch' => 'networks#advancedsearch'
  # get '/advancedsearchistory' => 'networks#advancedsearchistory'
#   
  # get '/getallleveldata' => 'networks#getallleveldata'
  # post '/getallleveldata' => 'networks#getallleveldata'
#   
  # #this one is for testing
  # get '/getconversion' => 'application#getconversion'
  
  
  
  # get '/bulkupload/add' => 'networks#bulkuploadadd'
  # get '/bulkupload/edit' => 'networks#bulkuploadedit'
  # get '/bulk/summary' => 'networks#bulksummary'
#   
  # post '/getbulkjob' => 'networks#getbulkjob'
  # post '/cancelbulkjob' => 'networks#cancelbulkjob'
  # post '/resumebulkjob' => 'networks#resumebulkjob'
#   
  # # post '/bulkjob' => 'networks#bulkjob'
#   
  # post '/bulkaddcampaign' => 'networks#bulkaddcampaign'
  # post '/bulkaddadgroup' => 'networks#bulkaddadgroup'
  # post '/bulkaddad' => 'networks#bulkaddad'
  # post '/bulkaddkeyword' => 'networks#bulkaddkeyword'
#   
  # post '/bulkeditcampaign' => 'networks#bulkeditcampaign'
#   
  # post '/advancesearchjob' => 'networks#advancesearchjob'
  # post '/advancesearchjobupdate' => 'networks#advancesearchjobupdate'
  # post '/canceladvancesearchjob' => 'networks#canceladvancesearchjob'
#   
  # post '/advancesearchadgroup' => 'networks#advancesearchadgroup'
  # post '/advancesearchadgroupupdate' => 'networks#advancesearchadgroupupdate'
#   
  # post '/getadvancesearch' => 'networks#getadvancesearch'
  
  
  # get '/test' => 'users#index'
  # get '/drop' => 'application#drop'
  
  # get '*unmatched_route' => 'application#raise_not_found'
  # get '404', to: 'application#page_not_found'
  # get '422', to: 'application#server_error'
  # get '500', to: 'application#server_error'
   
  get '*unmatched_route' => 'application#not_found'
  # Example of regular route:
    # get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
