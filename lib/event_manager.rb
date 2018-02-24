require "csv"
require "google/apis/civicinfo_v2"
require 'erb'



def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_num(num)

    clean_num = String.new
    

    num.to_s.split("").each do |character|
        clean_num << character if character.match(/\d/)
    end

    
    if clean_num.length == 10
        num = clean_num
    elsif clean_num[0] == "1" && clean_num.length == 11
        num = clean_num[1..-1]
    end

    reg_num = num.match(/(\d{3})(\d{3})(\d{4})/)

    num = "#{reg_num[1]}.#{reg_num[2]}.#{reg_num[3]}" if num.length == 10


        
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
                                    address: zip,
                                    levels: 'country',
                                    roles: ['legislatorUpperBody', 'legislatorLowerBody'])
        legislators = legislators.officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def save_thank_you_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts "EventManager Initialized!"


contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    phone_num = clean_phone_num(row[:homephone])

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letters(id, form_letter)

    puts "#{name} #{phone_num}"

end
