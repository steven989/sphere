module GoogleContactsApi
  class User

    # Extending the gem to include the ability to retrieve a single contact by ID
    def retrieve_contact(id,params = {})
      # contacts in this group
      @contacts ||= get_contact_by_id(id,params)
    end

  end

  module Contacts
    # Retrieve the contacts for this user or group
    def get_contact_by_id(id,params = {})
      # TODO: Should return empty ContactSet (haven't implemented one yet)
      return [] unless @api
      params = params.with_indifferent_access

      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder, group
      params["max-results"] = 100000 unless params.key?("max-results")
      url = "contacts/default/full/#{id}"
      response = @api.get(url, params)
      
      # TODO: Define some fancy exceptions
      case GoogleContactsApi::Api.parse_response_code(response)
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      GoogleContactsApi::ContactSet.parseSingleContact(response.body, @api)
    end
  end

  # Represents a set of contacts.
  class ContactSet < GoogleContactsApi::ResultSet
    # Initialize a ContactSet from an API response body that contains contacts data
    def self.parseSingleContact(response_body, api = nil)
      parsed = JSON.parse(response_body)
      puts '---------------------------------------------------'
      puts parsed.inspect
      puts '---------------------------------------------------'
      {
        id:parsed["entry"]["id"]["$t"],
        first_name:parsed["entry"]["gd$name"]["gd$givenName"]["$t"],
        last_name:parsed["entry"]["gd$name"]["gd$familyName"]["$t"],
        emaisl:parsed["entry"]["gd$email"]
      }
    end
  end


end

