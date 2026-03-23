namespace :notes do
  desc 'Create example notes for root@root'
  task create_examples: :environment do
    user = User.find_by(email: 'root@root')
    unless user
      puts 'User root@root not found. Run users:create_root first.'
      exit
    end

    puts 'Creating example notes...'

    # Tags
    tags = {}
    %w[personal work ideas shopping health travel].each do |name|
      tags[name] = user.note_tags.find_or_create_by!(name: name)
    end

    # Note 1: Shopping list with nested points
    n = user.notes.create!(title: 'Weekly Groceries', body: '')
    milk = n.note_points.create!(text: 'Dairy', position: 0)
    milk.children.create!(note: n, text: 'Whole milk 2L', position: 0)
    milk.children.create!(note: n, text: 'Greek yogurt', position: 1, checked: true)
    milk.children.create!(note: n, text: 'Butter', position: 2)
    vegs = n.note_points.create!(text: 'Vegetables', position: 1)
    vegs.children.create!(note: n, text: 'Tomatoes', position: 0, checked: true)
    vegs.children.create!(note: n, text: 'Cucumbers', position: 1)
    vegs.children.create!(note: n, text: 'Bell peppers', position: 2)
    n.note_points.create!(text: 'Bread', position: 2, checked: true)
    n.note_points.create!(text: 'Eggs (12 pack)', position: 3)
    n.note_points.create!(text: 'Olive oil', position: 4)
    n.note_tags << tags['shopping']
    n.note_tags << tags['personal']

    # Note 2: Text-only note
    n = user.notes.create!(
      title: 'Book Recommendations',
      body: "1. Sapiens by Yuval Noah Harari\n2. Atomic Habits by James Clear\n3. Deep Work by Cal Newport\n4. The Pragmatic Programmer\n5. Designing Data-Intensive Applications"
    )
    n.note_tags << tags['personal']

    # Note 3: Work meeting notes
    n = user.notes.create!(title: 'Sprint Planning', body: '')
    n.note_points.create!(text: 'Review backlog priorities', position: 0, checked: true)
    n.note_points.create!(text: 'Estimate new stories', position: 1, checked: true)
    n.note_points.create!(text: 'Assign tasks for next sprint', position: 2)
    n.note_points.create!(text: 'Update roadmap timeline', position: 3)
    n.note_points.create!(text: 'Schedule design review', position: 4)
    n.note_tags << tags['work']

    # Note 4: Short text note
    n = user.notes.create!(
      title: 'API Keys',
      body: "Remember to rotate API keys before March 30.\nCheck staging and production separately."
    )
    n.note_tags << tags['work']

    # Note 5: Travel planning
    n = user.notes.create!(title: 'Belgrade Trip', body: "Flying in April 15-22")
    n.note_points.create!(text: 'Book flights', position: 0, checked: true)
    n.note_points.create!(text: 'Reserve hotel', position: 1, checked: true)
    n.note_points.create!(text: 'Get travel insurance', position: 2)
    n.note_points.create!(text: 'Pack essentials', position: 3)
    n.note_points.create!(text: 'Download offline maps', position: 4)
    n.note_tags << tags['travel']
    n.note_tags << tags['personal']

    # Note 6: Ideas
    n = user.notes.create!(
      title: 'App Ideas',
      body: "- Habit tracker with streaks\n- Recipe manager with ingredient scaling\n- Local events aggregator\n- Shared grocery list for roommates"
    )
    n.note_tags << tags['ideas']

    # Note 7: Health
    n = user.notes.create!(title: 'Morning Routine', body: '')
    n.note_points.create!(text: 'Wake up at 7:00', position: 0)
    n.note_points.create!(text: '10 min meditation', position: 1)
    n.note_points.create!(text: 'Exercise 30 min', position: 2)
    n.note_points.create!(text: 'Cold shower', position: 3)
    n.note_points.create!(text: 'Healthy breakfast', position: 4)
    n.note_tags << tags['health']

    # Note 8: No tags, no points, just body
    user.notes.create!(
      title: '',
      body: "Call dentist tomorrow to reschedule appointment."
    )

    # Note 9: Long checklist
    n = user.notes.create!(title: 'Home Improvements', body: '')
    ['Fix kitchen faucet', 'Paint bedroom wall', 'Replace bathroom mirror',
     'Install new shelves', 'Fix squeaky door', 'Clean gutters',
     'Organize garage', 'Replace light bulbs'].each_with_index do |text, i|
      n.note_points.create!(text: text, position: i, checked: i < 3)
    end

    # Note 10: Mixed content
    n = user.notes.create!(
      title: 'Project Architecture',
      body: "Use event-driven design.\nKeep services stateless.\nPostgres for main DB, Redis for caching."
    )
    n.note_points.create!(text: 'Define API contracts', position: 0)
    n.note_points.create!(text: 'Set up CI/CD pipeline', position: 1, checked: true)
    n.note_points.create!(text: 'Write integration tests', position: 2)
    n.note_tags << tags['work']
    n.note_tags << tags['ideas']

    puts "Created #{user.notes.count} notes, #{NotePoint.where(note: user.notes).count} points, #{user.note_tags.count} tags"
  end
end
