json.array!(@networks) do |network|
  json.extract! network, :id
  json.url network_url(network, format: :json)
end
