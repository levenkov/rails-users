namespace :users do
  desc 'Create root user (root@example.com / password)'
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

  desc 'Create 100 example users'
  task create_examples: :environment do
    puts 'Creating 100 example users...'

    created_count = 0
    failed_count = 0

    100.times do |i|
      user = User.new(
        name: "Example User #{i + 1}",
        email: "user#{i + 1}@example.com",
        password: 'password123',
        password_confirmation: 'password123',
        role: :regular
      )

      if user.save
        created_count += 1
        print '.'
      else
        failed_count += 1
        puts "\nFailed to create user #{i + 1}: #{user.errors.full_messages.join(', ')}"
      end
    end

    puts "\n\nCompleted!"
    puts "Created: #{created_count} users"
    puts "Failed: #{failed_count} users" if failed_count > 0
  end

  desc 'Create NX testers'
  task create_nx_testers: :environment do
    emails = %w[
      alevenkov@networkoptix.com
      dsavinov@networkoptix.com
      rzinatullin@networkoptix.com
      epocherevina@networkoptix.com
      lbusygin@networkoptix.com
      dalferov@networkoptix.com
      esobolev@networkoptix.com
      sbelov@networkoptix.com
      mpodstrechny@networkoptix.com
      pstankovic@networkoptix.com
      asemenkov@networkoptix.com
      myanovich@networkoptix.com
      nzivkovic@networkoptix.com
      vbreus@networkoptix.com
      maltera@networkoptix.com
      anikitin@networkoptix.com
      ashapovalova@networkoptix.com
    ]

    emails.each do |email|
      name = email.split('@').first.capitalize
      user = User.find_or_initialize_by(email: email)
      user.assign_attributes(name: name, password: 'qweasd234', password_confirmation: 'qweasd234')

      if user.save
        print '.'
      else
        puts "\nFailed: #{email}: #{user.errors.full_messages.join(', ')}"
      end
    end

    puts "\nDone."
  end

  desc 'Delete all example users (user*@example.com)'
  task delete_examples: :environment do
    puts 'Deleting example users...'

    users = User.where('email LIKE ?', 'user%@example.com')
    count = users.count

    if count.zero?
      puts 'No example users found.'
    else
      users.destroy_all
      puts "Deleted #{count} example users."
    end
  end
end
