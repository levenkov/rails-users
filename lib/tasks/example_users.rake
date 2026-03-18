namespace :users do
  desc 'Create root user (root@root / password)'
  task create_root: :environment do
    puts 'Creating root user...'

    if User.count.positive?
      puts 'Root user already exists.'
      exit
    end

    user = User.find_or_initialize_by(email: 'root@root')
    user.assign_attributes(
      name: 'Root',
      password: 'qweasd234',
      password_confirmation: 'qweasd234',
      role: :admin
    )

    if user.save
      puts '✓ Root user created successfully!'
      puts "  Email: #{user.email}"
      puts "  Password: #{user.password}"
    else
      puts "✗ Failed to create root user: #{user.errors.full_messages.join(', ')}"
    end
  end
end
