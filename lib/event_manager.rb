require "csv"
require "google/apis/civicinfo_v2"
require 'erb'



# Return string for registered hour
def get_hour(reg_time)
    time = clean_time(reg_time)
    hour = time.strftime("%I %P")
end

# Return string for registered day
def get_day(reg_time)
    time = clean_time(reg_time)
    day = time.strftime("%A")
end

# Take user time and create proper DateTime instance
def clean_time(dirty_time)
    DateTime.strptime(dirty_time, '%m/%d/%y %k:%M')
end

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
    else
        return "invalid phone number"
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


hours_hash = {}
days_hash = {}

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

    hour = get_hour(row[:regdate])
    if hours_hash[hour].nil?
        hours_hash[hour] = 1
    else
        hours_hash[hour] += 1
    end

    day = get_day(row[:regdate])
    if days_hash[day].nil?
        days_hash[day] = 1
    else
        days_hash[day] += 1
    end

    puts "#{name} #{phone_num}"

end

puts "\nBest Hours: "
hours_hash = hours_hash.sort_by { |key, val| val }
hours_hash.reverse.each do |key, val|
    puts "#{val} users registered at #{key}"
end

puts "\nBest Days:"
days_hash = days_hash.sort_by { |key, val| val }
days_hash.reverse.each do |key, val|
    puts "#{val} users registered on #{key}"
end

