require 'bcrypt'

def hash_sensitive_value (inp)
  puts "Hashing using salt: '#{ENV['BCRYPT_SALT']}'"
  hash = BCrypt::Engine.hash_secret inp, ENV['BCRYPT_SALT']
  puts ".. Full hash: #{hash}"
  BCrypt::Password.new(hash).checksum # Unclear why ruby-bcrypt calls the hash a "checksum"
end

puts "Hashing: '#{ARGV[0]}'"

hashed = hash_sensitive_value ARGV[0]

puts "Final hashed value: '#{hashed}'"
