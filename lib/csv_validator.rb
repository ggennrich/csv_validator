require 'active_model'
require 'active_model/validations'
require 'csv'
require 'mail'

class CsvValidator < ActiveModel::EachValidator
  @@default_options = {}
  
  def self.default_options
    @@default_options
  end
  
  def validate_each(record, attribute, value)
    options = @@default_options.merge(self.options)
    
    unless value
      record.errors.add(attribute, options[:message] || "must be present")
      return
    end
    
    begin
      csv = CSV.read(value.path)
    rescue CSV::MalformedCSVError
      record.errors.add(attribute, options[:message] || "is not a valid CSV file")
      return
    end
    
    if options[:columns]
      unless csv[0].length == options[:columns]
        record.errors.add(attribute, options[:message] || "should have #{options[:columns]} columns")
      end
    end

    if options[:max_columns]
      if csv[0].length > options[:max_columns]
        record.errors.add(attribute, options[:message] || "should have no more than #{options[:max_columns]} columns")
      end
    end

    if options[:min_columns]
      if csv[0].length < options[:min_columns]
        record.errors.add(attribute, options[:message] || "should have at least #{options[:min_columns]} columns")
      end
    end

    if options[:rows]
      unless csv.length == options[:rows]
        record.errors.add(attribute, options[:message] || "should have #{options[:rows]} rows")
      end
    end

    if options[:min_rows]
      if csv.length < options[:min_rows]
        record.errors.add(attribute, options[:message] || "should have at least #{options[:min_rows]} rows")
      end
    end

    if options[:max_rows]
      if csv.length > options[:max_rows]
        record.errors.add(attribute, options[:message] || "should have no more than #{options[:max_rows]} rows")
      end
    end

    if options[:numericality]
      options[:numericality].each do |column|
        numbers = column_to_array(csv, column)
        numbers.each do |number|
          unless is_numeric?(number)
            record.errors.add(attribute, options[:message] || "contains non-numeric content in column #{column+1}")
            break
          end
        end
      end
    end

    if options[:string_regex]
      options[:string_regex].each do |column, regex|
        strings = column_to_array(csv, column)
        strings.each do |string|
          unless regex_match?(string, regex)
            record.errors.add(attribute, options[:message] || "contains unexpected characters in column #{column+1}")
            break
          end
        end
      end
    end
  end
  
  private
  
  def column_to_array(csv, column_index)
    column_contents = []
    csv.each do |column|    
      column_contents << column[column_index].to_s.strip
    end
    column_contents
  end
  
  def is_numeric?(string)
    Float(string)
    true 
  rescue 
    false
  end
  
  def regex_match?(string, regex)
    string.scan(regex).present?
    true
  rescue
    false
  end
end
