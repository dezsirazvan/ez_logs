#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'cgi'

# Test login functionality
def test_login
  puts "Testing EZLogs login functionality..."
  
  # Test 1: Check if login page is accessible
  puts "\n1. Testing login page accessibility..."
  response = Net::HTTP.get_response(URI('http://localhost:3000/users/sign_in'))
  if response.code == '200'
    puts "✅ Login page is accessible"
  else
    puts "❌ Login page returned #{response.code}"
    return false
  end
  
  # Test 2: Check if dashboard redirects to login when not authenticated
  puts "\n2. Testing dashboard redirect when not authenticated..."
  response = Net::HTTP.get_response(URI('http://localhost:3000/dashboard'))
  if response.code == '302' && response['location'].include?('sign_in')
    puts "✅ Dashboard correctly redirects to login when not authenticated"
  else
    puts "❌ Dashboard redirect issue: #{response.code}"
    return false
  end
  
  # Test 3: Check if admin dashboard redirects to login when not authenticated
  puts "\n3. Testing admin dashboard redirect when not authenticated..."
  response = Net::HTTP.get_response(URI('http://localhost:3000/admin/dashboard'))
  if response.code == '302' && response['location'].include?('sign_in')
    puts "✅ Admin dashboard correctly redirects to login when not authenticated"
  else
    puts "❌ Admin dashboard redirect issue: #{response.code}"
    return false
  end
  
  puts "\n✅ All basic authentication tests passed!"
  puts "\nTo test actual login:"
  puts "1. Open http://localhost:3000 in your browser"
  puts "2. Use admin@ezlogs.com / password123 to log in"
  puts "3. The system should redirect to the dashboard"
  
  true
rescue => e
  puts "❌ Error during testing: #{e.message}"
  false
end

# Run the test
test_login 