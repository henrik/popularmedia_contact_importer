# PopularMedia Contact Importer class for Ruby
# by Henrik Nyh <http://henrik.nyh.se> of DanceJam.com, 2008-10-06
# under the MIT license:
#
#   Copyright (c) 2008 Henrik Nyh and DanceJam.com
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#   THE SOFTWARE.
#
# Based on http://www.popularmedia.com/clientcenter/contact_importer_api/sample_code.php.
#
# Usage example:
#
#   ci = ContactImporter.new(
#     :api_key    => '00000000-0000-0000-0000-000000000000',
#     :api_secret => '1111111111111111111111111111111111111111',
#     :email      => 'user@gmail.com',
#     :password   => 'sesame',
#     :provider   => :gmail
#   )
#   contacts = ci.get_contacts
#
# The returned contacts will be an array of ContactImporter::Contact objects, where each
# object responds to #name and #email.
#
# Supported providers at the time of writing are :yahoo, :gmail, :aol, :msn and :hotmail.
# See http://www.popularmedia.com/clientcenter/contact_importer_api/parameters.php.

  
%w[rubygems uri net/https digest/md5 rexml/document].each {|f| require f }
  
class ContactImporter

  Contact = Struct.new(:name, :email)

  class Error < StandardError
    attr :code
    def initialize(code)
      @code = code
    end
  end

  class BadResponse < StandardError; end
     
  def initialize(args={})
    @request_parameters = {
      'method'  => 'import.contacts',
      'version' => '1.0',
      'web_service_api_key' => args[:api_key].to_s,
      'user_email_address'  => args[:email].to_s,
      'user_email_password' => args[:password].to_s,
      'contact_provider_id' => args[:provider].to_s.upcase
    }
    @shared_secret = args[:api_secret]
  end

  def get_contacts
    xml = get_xml
    
    begin
      doc = REXML::Document.new(xml)
      status = doc.root.attributes['stat']
    rescue
      raise BadResponse, %{Expected something with <response stat="...">, got #{xml.inspect}}
    end
      
    case status
    when 'ok'
      doc.elements.to_a('//contact').map do |c|
        name  = c.elements['name'].text
        email = c.elements['email'].text
        Contact.new(name, email)
      end
    when 'fail'
      error = doc.root.elements['error']
      code  = error.attributes['code']
      message = error.elements['message'].text
      raise Error.new(code), %{#{code}: #{message}}
    else
      raise BadResponse, %{Expected a response status of "ok" or "fail", got #{status.inspect}}
    end
  end

protected

  def get_xml
    catd_values = catd_params = ''
    @request_parameters.keys.sort.each {|param|
      catd_values += (param + @request_parameters[param])
    }

    catd_values = @shared_secret + catd_values
    @request_parameters['api_sig'] = Digest::MD5.hexdigest(catd_values)

    net_http = Net::HTTP.new('api.popularmedia.com', 443)
    net_http.use_ssl = true

    response = nil
    net_http.start do |http|
      request = Net::HTTP::Post.new('/rest')
      request.form_data = @request_parameters
      response = http.request(request)
    end

    response.body
  end

end
