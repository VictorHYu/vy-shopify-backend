class CustomersController < ApplicationController
  
  def index
    # get json from first customers page
    uri = URI.parse('https://backend-challenge-winter-2017.herokuapp.com/customers.json')
    req = Net::HTTP.get(uri)
    data_hash = JSON.parse(req)
    
    # get total number of pages
    total_customers = data_hash['pagination']['total']
    per_page = data_hash['pagination']['per_page']
    total_pages = (total_customers*1.0/per_page).ceil
    
    # array that holds invalid customers
    invalid_customers = Array.new
    
    # loop through pages
    for page_counter in 1..total_pages
      data_hash['customers'].each do |customer|
        # array that tracks which requirements are invalid
        error_info = Array.new
        
        # loop through the required validations
        data_hash['validations'].each do |validation|
          # loop through validation parameters
          validation.each do |field_name, validation_requirements|
            found_error = false
            
            # ASSUMPTIONS
            # - 'required' is always invalid when value is nil or missing from hash
            # - 'type' is always valid when value is nil
            # - 'length' is never valid when value is nil
            
            # check if field is required
            if (validation_requirements.key?('required') && validation_requirements['required'])
              if (!customer.key?(field_name) || customer[field_name] == nil)
                found_error = true
              end
            end
            
            # check length
            if (!found_error && validation_requirements.key?('length'))
              if (customer[field_name] == nil ||
                  ((validation_requirements['length'].key?('min') && customer[field_name].length < validation_requirements['length']['min']) ||
                  (validation_requirements['length'].key?('max') && customer[field_name].length > validation_requirements['length']['max'])))
                found_error = true
              end
            end
            
            # check type
            if (!found_error && customer[field_name] != nil && validation_requirements.key?('type'))
              if ((validation_requirements['type'] == 'number' && !(customer[field_name].is_a? Numeric)) ||
                   (validation_requirements['type'] == 'string' && !(customer[field_name].is_a? String)) ||
                   (validation_requirements['type'] == 'boolean' && !(!!customer[field_name] == customer[field_name])))
                found_error = true
              end
            end
            
            # add to array of invalid fields if an error was found
            if (found_error)
              error_info.push(field_name)
            end
          end
        end
        
        if (!error_info.empty?)
          invalid_customers.push({ "id" => customer['id'], "invalid_fields" => error_info })
        end
      end
      
      # get customers from next page
      # (assume validation parameters are the same across all pages)
      uri = URI.parse('https://backend-challenge-winter-2017.herokuapp.com/customers.json?page=' + (page_counter + 1).to_s)
      req = Net::HTTP.get(uri)
      data_hash = JSON.parse(req)
    end
    
    @text =
    '{' +
      '"invalid_customers": [' +
        invalid_customers.to_json +
      ']' +
    '}';
  end
end
