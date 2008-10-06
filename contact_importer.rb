#!/usr/bin/ruby

%w[
  rubygems
  uri
  net/https
  digest/md5
].each do |f|
  require f
end

class ShareByEmail

  def initialize(args ={})
    @request_parameters = {
      'method' => 'import.contacts',
      'version' => '1.0',
      'web_service_api_key' => args['my_web_service_key'] || '',
      'user_email_address' => args['user_email_address'] || '',
      'user_email_password' => args['user_email_password'] || '',
      'contact_provider_id' => args['contact_provider_id'] || ''
    }
    @shared_secret = args['my_secret_key']
  end

  def get_contacts
    catd_values = catd_params = ''
    @request_parameters.keys.sort.each{ |param|
      catd_values += (param + @request_parameters[param])
    }

    catd_values = @shared_secret + catd_values
    puts catd_values
    @request_parameters['api_sig'] = Digest::MD5.hexdigest(catd_values)

    net_http = Net::HTTP.new('api.popularmedia.com', 443)
    net_http.use_ssl = true

    response = nil 
    net_http.start do |http|
      request = Net::HTTP::Post.new('/rest')
      request.form_data = @request_parameters
      response = http.request(request)
    end

    return response.body
  end

end 

sbe = ShareByEmail.new( {
  'my_web_service_key' => 'your_web_service_api_key',
  'my_secret_key' => 'your_shared_secret',
  'user_email_address' => 'your_email_address',
  'user_email_password' => 'your_user_email_password',
  'contact_provider_id' => 'your_contact_provider_id'
})

puts sbe.get_contacts 								
