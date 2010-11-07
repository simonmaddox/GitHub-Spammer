#!/usr/bin/ruby
require 'rubygems'
require 'json'
require "net/http"
require 'uri'
require "cgi"
require 'pony'

# We need 3 params
abort("Invalid usage. Try:
  ruby " + __FILE__ + " \"Search Query\" \"Email Subject\" email_body.txt
  ruby " + __FILE__ + " \"Search Query\" \"Email Subject\" \"This is my awesome email\"
") if ARGV.count != 3

SMTP_OPTIONS = {
  :address              => 'CHANGEME',
  :port                 => '25',
  :enable_starttls_auto => true,
  :user_name            => 'CHANGEME',
  :password             => 'CHANGEME',
  :authentication       => :plain,
  :domain               => "localhost.localdomain"
}

# Let's make sure the user has actually configured SMTP. No guarantee details will be correct, but an easy first pass
abort ("You need to configure your SMTP settings in " + __FILE__ + "\n") if SMTP_OPTIONS[:address] == 'CHANGEME'

search = CGI::escape(ARGV[0].to_s)

# Go perform the search
repositories = JSON::parse(Net::HTTP.get URI.parse('http://github.com/api/v2/json/repos/search/' + search))

# Loop through each repo
repositories["repositories"].each { | repo | 
  
  # Fetch each user
  user = JSON::parse(Net::HTTP.get URI.parse("http://github.com/api/v2/json/user/show/" + repo['username']))["user"]
  
  # Figure out whether we need to read in a file, or just take the parameter as given
  body = (File.file?(ARGV[2].to_s) && File.read(ARGV[2].to_s)) || ARGV[2].to_s
  
  # And send the email!
  print "Emailing: " + user['email'] + "\n" if (!user['email'].nil? && user['email'].length > 0)
  
  Pony.mail(
    :to => user['email'],
    :subject => ARGV[1].to_s, 
    :body => body,
    :from => 'GitHub Spammer',
    :via => :smtp, 
    :via_options => SMTP_OPTIONS) if (!user['email'].nil? && user['email'].length > 0)
}